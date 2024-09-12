#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")/..")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

while getopts u flag
do
    case "${flag}" in
        u)
            undo="-undo"
            warningf "Undoing migration..."
            ;;
        *)
            echo "Unknown flag passed: '${flag}'" >&2
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))
[[ "${0}" == "--" ]] && shift

arg_num=0
if [ "$#" -ne "$arg_num" ]; then
    errorf "Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" conf_vars

load_conf_vars

if [ "${tf_usage:-true}" != 'true' ]; then
  notef "Skipped Terraform related migration because it is disabled."
  exit 0
fi

if [ -e "$code_repository/terraform" ]; then
    run rm -rf "$code_repository/terraform"
fi

"$actions_dir/update-inventory.sh" terraform

tf_prepare

pushd "$terraform_state_dir"

tf_init

notef "Checking if Terraform state migrations exist..."
set -f # disable glob expansion because we need to pass TAROOK_NIX_FLAGS unquoted
 # shellcheck disable=SC2086
migrations=$(nix build --override-input yk8s "$code_repository" --print-out-paths --no-link --show-trace ${TAROOK_NIX_FLAGS:-} ".#tf-state-migrations${undo:-}")
set +f
if ! [ -s "$migrations" ]; then
    notef "Nothing to do."
    exit 0
fi

if [ -z "${undo:-}" ] ; then
    notef "Checking if Terraform state migration is necessary..."
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
else
    warningf "Undoing Terraform state migration..."
fi


tf_statefile_temp="$terraform_state_dir/terraform.tfstate.tmp"
terraform state pull > "$tf_statefile_temp"

# shellcheck disable=SC1090
source "$migrations"

run terraform state push "$tf_statefile_temp"

if [ -n "${undo:-}" ]; then
    notef "Terraform state migration undone."
    exit 0
fi

notef "Terraform state migration done."
notef "Running apply-terraform to create their replacements..."

popd

# Ensure that this is run without disruption in order to catch mismatches
MANAGED_K8S_DISRUPT_THE_HARBOUR=false run "$actions_dir/apply-terraform.sh"

run rm -f "$tf_statefile_temp"*

run git add "$terraform_state_dir"
