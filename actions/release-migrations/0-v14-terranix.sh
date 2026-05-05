#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" conf_vars

load_conf_vars

if [ "${tf_usage:-true}" != 'true' ]; then
  notef "Skipped Terraform related migration because it is disabled."
  exit 0
fi

notef "Removing obsolete state files..."

vars_file="$terraform_state_dir/config.tfvars.json"
if [ -f "$vars_file" ]; then
    if git ls-files --error-unmatch "$vars_file" &> /dev/null; then
        git rm "$vars_file"
    else
        rm "$vars_file"
    fi
fi

plan_file="$terraform_state_dir/plan.tfplan"
if [ -f "$plan_file" ]; then
    if git ls-files --error-unmatch "$plan_file" &> /dev/null; then
        git rm --cached "$plan_file"
    fi
fi

"$actions_dir/update-inventory.sh" terraform

tf_prepare
pushd "$terraform_state_dir"

load_gitlab_vars

if [ "$gitlab_backend" = false ]; then
    notef "Updating path of local state..."
    run terraform init -migrate-state
fi

popd
