#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" conf_vars

load_conf_vars

check_venv

if [ "$("$actions_dir/helpers/semver2.sh" "$(terraform -v -json | jq -r '.terraform_version')" "$terraform_min_version")" -lt 0 ]; then
    errorf 'Please upgrade Terraform to at least v'"$terraform_min_version"
    exit 5
fi

"$actions_dir/update-inventory.sh" terraform

var_file="$terraform_state_dir/config.tfvars.json"
cd "$terraform_state_dir"

tf_init

run terraform -chdir="$terraform_module" plan --var-file="$var_file" --out "$terraform_plan"
# strict mode terminates the execution of this script immediately
set +e
terraform -chdir="$terraform_module" show -json "$terraform_plan" | python3 "$actions_dir/helpers/check_plan.py"
rc=$?
set -e
RC_DISRUPTION=47
RC_NO_DISRUPTION=0
if [ $rc == $RC_DISRUPTION ]; then
    if ! harbour_disruption_allowed; then
        # shellcheck disable=SC2016
        errorf 'terraform would delete or recreate a resource, but not all of the following is set' >&2
        errorf '  - MANAGED_K8S_DISRUPT_THE_HARBOUR=true' >&2
        errorf "  - terraform.prevent_disruption = false in the config" >&2
        errorf 'aborting due to destructive change without approval.' >&2
        exit 3
    fi
    warningf 'terraform will perform destructive actions' >&2
    # shellcheck disable=SC2016
    warningf 'approval was given by setting $MANAGED_K8S_DISRUPT_THE_HARBOUR' >&2
elif [ $rc != $RC_NO_DISRUPTION ] && [ $rc != $RC_DISRUPTION ]; then
    errorf 'error during execution of check_plan.py. Aborting' >&2
    exit 4
fi
run terraform -chdir="$terraform_module" apply "$terraform_plan" | sed '/Outputs:/,$d' # we don't want Terraform to dump all the outputs to the console
terraform -chdir="$terraform_module" output -json > "$terraform_state_dir/outputs.json"

if [ "$(jq -r .backend.type "$terraform_state_dir/.terraform/terraform.tfstate")" == 'http' ]; then
    notef 'Pulling latest Terraform state from Gitlab for disaster recovery purposes.'
    # don't use the "run" function here as it would print the token
    curl -s -o "$terraform_state_dir/disaster-recovery.tfstate.bak" \
        --header "Private-Token: $TF_HTTP_PASSWORD" "$backend_address"
fi
