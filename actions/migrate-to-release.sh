#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

check_venv

load_conf_vars  # sets tf_usage

if [ "${tf_usage:-true}" == 'true' ]; then
    require_harbour_disruption  # due to renaming of nodes in Openstack
fi

script_name="$(basename "$0")"


# Perform pre-checks

# Fail if config file is dirty
#  so that unstaged changes are not overwritten potentially
if ! git diff-files --quiet -- "${config_file}"; then
    errorf "${config_file} is dirty. Refusing to continue.
            Please retry after at least staging your changes."
    exit 5
fi


# Ensure prerequisites

# Initialize Terraform (if applicable)
# NOTE: terraform_migrate and `terraform show` below
#       expect Terraform to be initialized already
if [ "${tf_usage:-true}" == 'true' ]; then
    if [ "$(jq -r .gitlab_backend "$terraform_state_dir/config.tfvars.json")" = true ]; then
        load_gitlab_vars
        tf_init_http
    else
        tf_init_local
    fi
fi


# Perform Terraform migration steps (if applicable)
# NOTE: The current Terraform state is backed up by version control.
#       The apply-terraform action ensures that a local copy can always be checked in
#       in case of remote Terraform backends.

if [ "${tf_usage:-true}" == 'true' ]; then
    # count to for_each
    notef "${script_name}: Migrating count to for_each in Terraform state ..."
    # shellcheck disable=SC2046
    run python3 "$actions_dir"/helpers/terraform_migrate.py \
        --task count-to-for_each \
        -- "$terraform_module" \
    && if [ -f "$terraform_module/02-moved-instances.tf" ]; then
        # This file is not needed anymore
        # since the Terraform state was migrated permanently
        rm "$terraform_module/02-moved-instances.tf"
    fi

    # index based gateway names
    notef "${script_name}: Renaming gateways to index based naming scheme in Terraform state and Openstack ..."
    run python3 "$actions_dir"/helpers/terraform_migrate.py \
        --task index-based-gateway-names --config-file "${config_file}" \
        -- "$terraform_module"

    # per worker anti affinity server group
    notef "${script_name}: Adapting anti affinity server group in Terraform ..."
    run python3 "$actions_dir"/helpers/terraform_migrate.py \
        --task per-worker-anti-affinity-group --config-file "${config_file}" \
        -- "$terraform_module"
fi


# Perform config migration steps

# conversion of the terraform config section if enabled
if [ "${tf_usage:-true}" == 'true' ]; then
    notef "${script_name}: Converting the '[terraform]' config section into the new format ..."
    {
        {
            if [ "${tf_usage:-true}" == 'true' ]; then
                terraform -chdir=managed-k8s/terraform/ show -json
            else
                printf 'null'
            fi
        } \
            | python3 "$actions_dir/helpers/config_migrate.py" - "$config_file" \
                > "$config_file.yk8snew" \
        && mv "$config_file.yk8snew" "${config_file}"
    } && {
        notef "${script_name}: Converted. Please review and stage the diff below:"
        git --no-pager diff -- "$config_file"
    }
fi
