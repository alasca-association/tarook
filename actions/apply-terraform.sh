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
if [ "$(jq -r .gitlab_backend "$terraform_state_dir/config.tfvars.json")" = true ]; then
    # Here we create a override file which overrides the `local` terraform backend to http(gitlab) backend
    if [ ! -f "$OVERRIDE_FILE" ]; then
		cat > "$OVERRIDE_FILE" <<-EOF
		terraform {
			backend "http" {}
		}
		EOF
    fi
    # setting vars for terraform backend config for gitlab-managed terraform backend
    gitlab_base_url="$(jq -r .gitlab_base_url   "$terraform_state_dir/config.tfvars.json")"
    gitlab_project_id="$(jq -r .gitlab_project_id "$terraform_state_dir/config.tfvars.json")"
    gitlab_state_name="$(jq -r .gitlab_state_name "$terraform_state_dir/config.tfvars.json")"
    backend_address="$gitlab_base_url/api/v4/projects/$gitlab_project_id/terraform/state/$gitlab_state_name"

    run terraform -chdir="$terraform_module" init \
                  -migrate-state \
                  -force-copy \
                  -backend-config="address=$backend_address" \
                  -backend-config="lock_address=$backend_address/lock" \
                  -backend-config="unlock_address=$backend_address/lock" \
                  -backend-config="lock_method=POST" \
                  -backend-config="unlock_method=DELETE" \
                  -backend-config="retry_wait_min=5"
else
    if [ -f "$OVERRIDE_FILE" ]; then
        rm "$OVERRIDE_FILE"
    fi
    run terraform -chdir="$terraform_module" init \
                  -migrate-state \
                  -force-copy
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
