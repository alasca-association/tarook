#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

cd "$terraform_state_dir"
run terraform init "$terraform_module"
run terraform plan --var-file=./config.tfvars.json --out "$terraform_plan" "$terraform_module"
if [ "x$(terraform show --json "$terraform_plan" | jq -r '.resource_changes | map(select(.provider_name != "local")) | map(.change.actions) | flatten | map(. == "delete") | any')" != 'xfalse' ]; then
    if ! disruption_allowed; then
        # shellcheck disable=SC2016
        errorf 'terraform would delete or recreate a resource, but $MANAGED_K8S_RELEASE_THE_KRAKEN is not set' >&2
        errorf 'aborting due to destructive change without approval.' >&2
        exit 3
    fi
    warningf 'terraform will perform destructive actions' >&2
    # shellcheck disable=SC2016
    warningf 'approval was given by setting $MANAGED_K8S_RELEASE_THE_KRAKEN' >&2
fi
run terraform apply "$terraform_plan"
