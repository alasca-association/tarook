#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

check_venv

# Check for migration Terraform -> OpenTofu
if [ -d "$cluster_repository/terraform" ] && [ -d "$tofu_state_dir" ]; then
    errorf "$cluster_repository/terraform exists,"
    errorf "but $tofu_state_dir also exists."
    errorf "Somethings odd, migrating from Terraform to OpenTofu probably failed."
    errorf "You have to manually merge $cluster_repository/terraform into $tofu_state_dir"
    exit 1
fi

if [ -d "$cluster_repository/terraform" ] && ! [ -d "$tofu_state_dir" ]; then
    notef "====="
    notef "Moving $cluster_repository/terraform to $tofu_state_dir"
    notef "====="
    mv "$cluster_repository/terraform" "$tofu_state_dir"
fi

# delete "${TOFU_MODULE_PATH:-$code_repository/terraform}/02-moved-instances.tf"
# after https://gitlab.com/yaook/k8s/-/merge_requests/933
if [ -f "${TOFU_MODULE_PATH:-$code_repository/tofu}/02-moved-instances.tf" ]; then
  run rm "${TOFU_MODULE_PATH:-$code_repository/tofu}/02-moved-instances.tf"
fi

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

if [ "$("$actions_dir/helpers/semver2.sh" "$(tofu -v -json | jq -r '.terraform_version')" "$tofu_min_version")" -lt 0 ]; then
    errorf 'Please upgrade OpenTofu to at least v'"$tofu_min_version"
    exit 5
fi

var_file="$tofu_state_dir/config.tfvars.json"
cd "$tofu_state_dir"
export TF_DATA_DIR="$tofu_state_dir/.terraform"

OVERRIDE_FILE="$tofu_module/backend_override.tf"

function tf_init_http () {
    run tofu -chdir="$tofu_module" init \
                  -upgrade \
                  -backend-config="address=$backend_address" \
                  -backend-config="lock_address=$backend_address/lock" \
                  -backend-config="unlock_address=$backend_address/lock" \
                  -backend-config="lock_method=POST" \
                  -backend-config="unlock_method=DELETE" \
                  -backend-config="retry_wait_min=5"
}

function tf_init_http_migrate () {
    run tofu -chdir="$tofu_module" init \
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

function tf_init_local () {
    run tofu -chdir="$tofu_module" init \
                  -upgrade
}

function tf_init_local_migrate () {
    run tofu -chdir="$tofu_module" init \
                  -migrate-state \
                  -force-copy \
                  -upgrade
    return $?
}

all_gitlab_vars=("gitlab_base_url" "gitlab_project_id" "gitlab_state_name")

function all_gitlab_vars_are_set() {
    for var in "${all_gitlab_vars[@]}"; do
        [[ -z "${!var}" || "${!var}" == "null" ]] && return 1
    done
    return 0
}

function all_gitlab_vars_are_unset() {
    for var in "${all_gitlab_vars[@]}"; do
        [[ -n "${!var}" && "${!var}" != "null" ]] && return 1
    done
    return 0
}

function tf_state_present_on_gitlab () {
    if [ -z "${TF_HTTP_PASSWORD:-}" ]; then
        errorf "We want to check if there is a Gitlab state present,"
        errorf "but no TF_HTTP_PASSWORD provided!"
        errorf "If you're using local backend"
        errorf "make sure that all the following GitLab variables are unset:"
        for var in "${all_gitlab_vars[@]}"; do
            errorf "- $var"
        done
        exit 2
    fi
    GITLAB_RESPONSE=$(curl -Is --header "Private-Token: $TF_HTTP_PASSWORD" -o "/dev/null" -w "%{http_code}" "$backend_address")
    check_return_code "$GITLAB_RESPONSE"
}

load_gitlab_vars

if all_gitlab_vars_are_set; then
    if tf_state_present_on_gitlab && [ -f "$tofu_state_dir/terraform.tfstate" ]; then
        errorf "Several OpenTofu statefiles were found: locally and on GitLab."
        exit 1
    fi
fi

# gitlab_backend=true
if [ "$(jq -r .gitlab_backend "$tofu_state_dir/config.tfvars.json")" = true ]; then
    if ! all_gitlab_vars_are_set; then
        errorf "'gitlab_backend=true' but GitLab variables are not (completely) provided."
        exit 2
    fi

    # Here we create an override_file which overrides the `local` tofu backend to http(gitlab) backend
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
        if  [ -f "$tofu_state_dir/terraform.tfstate" ]; then
            tf_init_http_migrate
            # Delete tofu statefiles locally if they exist (-f)
            rm -f "$tofu_state_dir/terraform.tfstate" "$tofu_state_dir/terraform.tfstate.backup"
        else
            tf_init_http    # first init
        fi
    fi

# gitlab_backend=false
else
    if ! all_gitlab_vars_are_set && ! all_gitlab_vars_are_unset; then
        errorf "'gitlab_backend=false' but some GitLab variables are provided."
        errorf "(1) If you want to migrate the OpenTofu backend method from 'http' to 'local',"
        errorf "you should provide all the GitLab variables"
        errorf "(2) If you want to init a cluster with local backend,"
        errorf "make sure that all the following GitLab variables are unset:"
        for var in "${all_gitlab_vars[@]}"; do
            errorf "- $var"
        done
        exit 2
    fi

    if all_gitlab_vars_are_set; then
        if tf_state_present_on_gitlab; then
            rm -f "$OVERRIDE_FILE"
            notef "OpenTofu statefile on GitLab found. Migration from http to local."
            if tf_init_local_migrate; then
                # delete tf_statefile from GitLab
                GITLAB_RESPONSE=$(curl -Is --header "Private-Token: $TF_HTTP_PASSWORD" -o "/dev/null" -w "%{http_code}" --request DELETE "$backend_address")
                check_return_code "$GITLAB_RESPONSE"
            else
                warningf "OpenTofu init was not successful. The OpenTofu state on GitLab was not deleted."
            fi
        else
            errorf "'gitlab_backend=false', all GitLab variables are provided,"
            errorf "but the Terrafrom state file could not be found on GitLab in order to migrate from 'http' to 'local'."
            errorf "(1) If you want to migrate, make sure the OpenTofu state file exists on GitLab."
            errorf "(2) If you want to init a cluster with local backend,"
            errorf "make sure that all the following GitLab variables are unset:"
            for var in "${all_gitlab_vars[@]}"; do
                errorf "- $var"
            done
            exit 2
        fi
    else
        rm -f "$OVERRIDE_FILE"
        tf_init_local
    fi
fi

run tofu -chdir="$tofu_module" plan --var-file="$var_file" --out "$tofu_plan"
# strict mode terminates the execution of this script immediately
set +e
tofu -chdir="$tofu_module" show -json "$tofu_plan" | python3 "$actions_dir/helpers/check_plan.py"
rc=$?
set -e
RC_DISRUPTION=47
RC_NO_DISRUPTION=0
if [ $rc == $RC_DISRUPTION ]; then
    if ! harbour_disruption_allowed; then
        # shellcheck disable=SC2016
        errorf 'tofu would delete or recreate a resource, but not all of the following is set' >&2
        errorf '  - MANAGED_K8S_DISRUPT_THE_HARBOUR=true' >&2
        errorf "  - ${tofu_disruption_setting}=false in ${config_file}" >&2
        errorf 'aborting due to destructive change without approval.' >&2
        exit 3
    fi
    warningf 'OpenTofu will perform destructive actions' >&2
    # shellcheck disable=SC2016
    warningf 'approval was given by setting $MANAGED_K8S_DISRUPT_THE_HARBOUR' >&2
elif [ $rc != $RC_NO_DISRUPTION ] && [ $rc != $RC_DISRUPTION ]; then
    errorf 'error during execution of check_plan.py. Aborting' >&2
    exit 4
fi
run tofu -chdir="$tofu_module" apply "$tofu_plan"

if [ "$(jq -r .backend.type "$tofu_state_dir/.terraform/terraform.tfstate")" == 'http' ]; then
    notef 'Pulling latest OpenTofu state from Gitlab for disaster recovery purposes.'
    # don't use the "run" function here as it would print the token
    curl -s -o "$tofu_state_dir/disaster-recovery.tfstate.bak" \
        --header "Private-Token: $TF_HTTP_PASSWORD" "$backend_address"
fi
