#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if [ "$("$actions_dir/helpers/semver2.sh" "$(terraform -v -json | jq -r '.terraform_version')" "$terraform_min_version")" -lt 0 ]; then
    errorf 'Please upgrade Terraform to at least v'"$terraform_min_version"
    exit 5
fi

var_file="$terraform_state_dir/config.tfvars.json"
cd "$terraform_state_dir"
export TF_DATA_DIR="$terraform_state_dir/.terraform"

OVERRIDE_FILE="$terraform_module/backend_override.tf"

tf_init_http () {
    run terraform -chdir="$terraform_module" init \
                  -upgrade \
                  -backend-config="address=$backend_address" \
                  -backend-config="lock_address=$backend_address/lock" \
                  -backend-config="unlock_address=$backend_address/lock" \
                  -backend-config="lock_method=POST" \
                  -backend-config="unlock_method=DELETE" \
                  -backend-config="retry_wait_min=5"
}

tf_init_http_migrate () {
    run terraform -chdir="$terraform_module" init \
                  -migrate-state \
                  -force-copy \
                  -upgrade \
                  -backend-config="address=$backend_address" \
                  -backend-config="lock_address=$backend_address/lock" \
                  -backend-config="unlock_address=$backend_address/lock" \
                  -backend-config="lock_method=POST" \
                  -backend-config="unlock_method=DELETE" \
                  -backend-config="retry_wait_min=5"
}

tf_init_local () {
    run terraform -chdir="$terraform_module" init \
                  -upgrade
}

tf_init_local_migrate () {
    run terraform -chdir="$terraform_module" init \
                  -migrate-state \
                  -force-copy \
                  -upgrade
    return $?
}

all_gitlab_vars=("gitlab_base_url" "gitlab_project_id" "gitlab_state_name" "TF_HTTP_PASSWORD")

all_gitlab_vars_are_set() {
    for var in "${all_gitlab_vars[@]}"; do
        [[ -z "${!var}" || "${!var}" == "null" ]] && return 1
    done
    return 0
}

all_gitlab_vars_are_unset() {
    for var in "${all_gitlab_vars[@]}"; do
        [[ -n "${!var}" && "${!var}" != "null" ]] && return 1
    done
    return 0
}

# true: HTTP/200 response; false: HTTP/404; exit: HTTP/*
tf_state_present_on_gitlab () {
    GITLAB_RESPONSE=$(curl -Is --header "Private-Token: $TF_HTTP_PASSWORD" -o "/dev/null" -w "%{http_code}" "$backend_address")
    if [ "$GITLAB_RESPONSE" == "200" ]; then
        return 0
    elif [ "$GITLAB_RESPONSE" == "404" ]; then
        return 1
    elif [ "$GITLAB_RESPONSE" == "401" ]; then
        echo
        notef "HTTP 401. The provided GitLab credentials seem to be invalid."
        exit 2
    else
        echo
        notef "Unexpected HTTP response: $GITLAB_RESPONSE"
        exit 1
    fi
}

load_gitlab_vars

if all_gitlab_vars_are_set; then
    if tf_state_present_on_gitlab && [ -f "$terraform_state_dir/terraform.tfstate" ]; then
        echo
        notef "Several Terraform statefiles were found: locally and on GitLab."
        exit 1
    fi
fi

# gitlab_backend=true
if [ "$(jq -r .gitlab_backend "$terraform_state_dir/config.tfvars.json")" = true ]; then
    if ! all_gitlab_vars_are_set; then
        echo
        notef "'gitlab_backend=true' but GitLab variables are not (completely) provided."
        exit 2
    fi

    # Here we create an override_file which overrides the `local` terraform backend to http(gitlab) backend
    if [ ! -f "$OVERRIDE_FILE" ]; then
		cat > "$OVERRIDE_FILE" <<-EOF
		terraform {
			backend "http" {}
		}
		EOF
    fi

    if tf_state_present_on_gitlab; then
        tf_init_http
    else
        if  [ -f "$terraform_state_dir/terraform.tfstate" ]; then
            tf_init_http_migrate
            # Delete terraform statefiles locally if they exist (-f)
            rm -f "$terraform_state_dir/terraform.tfstate" "$terraform_state_dir/terraform.tfstate.backup"
        else
            tf_init_http    # first init
        fi
    fi

# gitlab_backend=false
else
    if ! all_gitlab_vars_are_set && ! all_gitlab_vars_are_unset; then
        echo
        notef "'gitlab_backend=false' but some GitLab variables are provided.
(1) If you want to migrate the Terraform backend method from 'http' to 'local',
you should provide all the GitLab variables
and ensure, that the Terraform state exists on GitLab.
(2) If not, make sure that *all* GitLab variables are unset:"
        for var in "${all_gitlab_vars[@]}"; do
            echo "- $var"
        done
        exit 2
    fi

    if all_gitlab_vars_are_set; then
        if tf_state_present_on_gitlab; then
            rm -f "$OVERRIDE_FILE"
            notef "Terraform statefile on GitLab found. Migration from http to local."
            require_extremination    # check whether $MANAGED_K8S_NUKE_FROM_ORBIT=true
            if tf_init_local_migrate; then
                # delete tf_statefile from GitLab
                curl --header "Private-Token: $TF_HTTP_PASSWORD" --request DELETE "$backend_address"
            else
                notef "Terraform init was not successful. The Terraform state on GitLab was not deleted."
            fi
        else
            echo
            notef "'gitlab_backend=false', all GitLab variables are provided,
but the Terrafrom state file could not be found on GitLab in order to migrate from 'http' to 'local'.
(1) If you want to migrate, make sure the Terraform state file exists on GitLab.
(2) If not, make sure that *all* GitLab variables are unset:"
            for var in "${all_gitlab_vars[@]}"; do
                echo "- $var"
            done
            exit 2
        fi
    else
        rm -f "$OVERRIDE_FILE"
        tf_init_local
    fi
fi

# Prepare possible migration steps
# count -> foreach migration
# shellcheck source=actions/helpers/migrate-count-to-for-each.sh

if [ -f "$terraform_state_dir"/terraform.tfstate ]; then
  # Only attempt to migrate if we have a terraform state in first place
  source "$actions_dir"/helpers/migrate-count-to-for-each.sh
  run terraform_migrate_foreach "$terraform_module/02-moved-instances.tf"
fi

run terraform -chdir="$terraform_module" plan --var-file="$var_file" --out "$terraform_plan"
# strict mode terminates the execution of this script immediately
set +e
terraform -chdir="$terraform_module" show -json "$terraform_plan" | python3 "$actions_dir/helpers/check_plan.py"
rc=$?
set -e
RC_DISRUPTION=47
RC_NO_DISRUPTION=0
if [ $rc == $RC_DISRUPTION ]; then
    if ! disruption_allowed; then
        # shellcheck disable=SC2016
        errorf 'terraform would delete or recreate a resource, but $MANAGED_K8S_RELEASE_THE_KRAKEN is not set' >&2
        errorf 'aborting due to destructive change without approval.' >&2
        exit 3
    fi
    warningf 'terraform will perform destructive actions' >&2
    # shellcheck disable=SC2016
    warningf 'approval was given by setting $MANAGED_K8S_RELEASE_THE_KRAKEN' >&2
elif [ $rc != $RC_NO_DISRUPTION ] && [ $rc != $RC_DISRUPTION ]; then
    errorf 'error during execution of check_plan.py. Aborting' >&2
    exit 4
fi
run terraform -chdir="$terraform_module" apply "$terraform_plan"

if [ "$(jq -r .backend.type "$terraform_state_dir/.terraform/terraform.tfstate")" == 'http' ]; then
    echo
    notef 'Pulling latest Terraform state from Gitlab for disaster recovery purposes.'
    # don't use the "run" function here as it would print the token
    curl -s -o "$terraform_state_dir/disaster-recovery.tfstate.bak" \
        --header "Private-Token: $TF_HTTP_PASSWORD" "$backend_address"
fi
