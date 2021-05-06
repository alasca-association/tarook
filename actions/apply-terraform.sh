#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

tf_min_version=14
if [ "$(terraform -v -json | jq -r '.terraform_version' | cut -d'.' -f2)" -lt "$tf_min_version" ]; then
    errorf 'Please upgrade Terraform to at least v0.'"$tf_min_version"'.0'
    exit 5
fi

cd "$terraform_state_dir"
run terraform init "$terraform_module"
run terraform plan --var-file=./config.tfvars.json --out "$terraform_plan" "$terraform_module"
# strict mode terminates the execution of this script immediately
set +e
terraform show --json "$terraform_plan" | python3 ../"$actions_dir/check_plan.py"
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
run terraform apply "$terraform_plan"
