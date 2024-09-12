#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")/..")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" conf_vars

load_conf_vars

if [ "${tf_usage:-true}" != 'true' ]; then
  notef "Skipped Terraform related migration because it is disabled."
  exit 0
fi

"$actions_dir/update-inventory.sh" terraform

pushd "$terraform_state_dir"

tf_init

notef "Checking if Terraform migrations exist..."
migrations=$(nix build --override-input yk8s "$code_repository" --print-out-paths --no-link --show-trace .#tf-state-migrations)
if ! [ -s "$migrations" ]; then
    notef "Nothing to do."
    exit 0
fi

notef "Checking if Terraform migration is necessary..."
run terraform plan --out "$terraform_plan"
# strict mode terminates the execution of this script immediately
set +e
terraform show -json "$terraform_plan" | python3 "$actions_dir/helpers/check_plan.py"
rc=$?
set -e
RC_DISRUPTION=47
RC_NO_DISRUPTION=0
if [ $rc == $RC_NO_DISRUPTION ]; then
    notef "Nothing to do."
    exit 0
elif [ $rc != $RC_NO_DISRUPTION ] && [ $rc != $RC_DISRUPTION ]; then
    errorf 'error during execution of check_plan.py. Aborting' >&2
    exit 4
fi

notef "Migrating Terraform state..."

tf_statefile_temp="$terraform_state_dir/terraform.tfstate.tmp"
terraform state pull > "$tf_statefile_temp"

# shellcheck disable=SC1090
source "$migrations"

run terraform state push "$tf_statefile_temp"

notef "Terraform state migration done."
notef "Running apply-terraform to create their replacements..."

popd

run "$actions_dir/apply-terraform.sh"


rm "$tf_statefile_temp"

run git add "$terraform_state_dir"
