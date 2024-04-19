#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

check_venv

if [ "$(jq -r .gitlab_backend "$terraform_state_dir/config.tfvars.json")" = true ]; then
    load_gitlab_vars  # sets $backend_address
fi


script_name="$(basename "$0")"


# Perform Terraform migration steps
# NOTE: The current Terraform state is backed up by version control.
#       The apply-terraform action ensures that a local copy can always be checked in
#       in case of remote Terraform backends.

# count to for_each
notef "${script_name}: Migrating count to for_each in Terraform state ..."
# shellcheck disable=SC2046
run python3 "$actions_dir"/helpers/terraform_migrate.py \
    $(test -z ${backend_address+x} || echo \
        --tf-gitlab-backend "'$backend_address'" \
    ) \
    --task count-to-for_each \
    -- "$terraform_module" \
&& if [ -f "$terraform_module/02-moved-instances.tf" ]; then
    # This file is not needed anymore
    # since the Terraform state was migrated permanently
    rm "$terraform_module/02-moved-instances.tf"
fi
