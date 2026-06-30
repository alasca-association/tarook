#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" conf_vars

load_conf_vars

check_venv

require_ansible_disruption

function destroy_terraform() {
    require_harbour_disruption

    "$actions_dir/update-inventory.sh" terraform


    if [ "$("$actions_dir/helpers/semver2.sh" "$(terraform -v -json | jq -r '.terraform_version')" "$terraform_min_version")" -lt 0 ]; then
        errorf 'Please upgrade Terraform to at least v'"$terraform_min_version"
        exit 5
    fi

    load_gitlab_vars

    cd "$terraform_state_dir"
    export TF_DATA_DIR="$terraform_state_dir/.terraform"
    run terraform init
    # The following task will fail if a) thanos wrote data into a container and b) `MANAGED_K8S_NUKE_FROM_ORBIT` is not set
    run terraform destroy --auto-approve || true

    # Remove the tf_statefile from gitlab
    if [ "$(jq -r .backend.type "$terraform_state_dir/.terraform/terraform.tfstate")" == 'http' ] ; then
        GITLAB_RESPONSE=$(curl -Is --header "Private-Token: $TF_HTTP_PASSWORD" -o "/dev/null" -w "%{http_code}" --request DELETE "$backend_address")
        check_return_code "$GITLAB_RESPONSE"
    fi

    # Purge the remaining terraform directory. Its existence is a condition for additional disruption checks.
    rm -fr "$terraform_state_dir"
}

function destroy_proxmox() {
    destroy_terraform
}

function destroy_openstack() {
    require_harbour_disruption

    "$actions_dir/update-inventory.sh" terraform


    if [ "$("$actions_dir/helpers/semver2.sh" "$(terraform -v -json | jq -r '.terraform_version')" "$terraform_min_version")" -lt 0 ]; then
        errorf 'Please upgrade Terraform to at least v'"$terraform_min_version"
        exit 5
    fi

    load_gitlab_vars

    IFS=$'\n'
    if [ "${MANAGED_K8S_NUKE_FROM_ORBIT:-}" = 'true' ]; then
        if [ "$(jq -r .backend.type "$terraform_state_dir/.terraform/terraform.tfstate")" == 'http' ] ; then
            container_id="$(curl -s --header "Private-Token: $TF_HTTP_PASSWORD" "$backend_address" | jq -r '((.resources | map(select(.name == "thanos_data" and .type == "openstack_objectstorage_container_v1")) | first).instances | first).attributes.id')"
        else
            container_id="$(jq -r '((.resources | map(select(.name == "thanos_data" and .type == "openstack_objectstorage_container_v1")) | first).instances | first).attributes.id' "$terraform_state_dir/terraform.tfstate")"
        fi
        if [ "$container_id" != 'null' ]; then
            printf 'Deleting object storage container contents of %q ...' "$container_id"
            while IFS=$'\n' read -r -d '' -a objects < <( openstack object list "$container_id" -f value && printf '\0' ); do
                if [ "${#objects[@]}" = '0' ]; then
                    break
                fi
                openstack object delete "$container_id" "${objects[@]}"
            done
            printf '\n'
        fi
    fi

    if [[ -z "${OS_PROJECT_ID+x}" ]]; then
        if [[ -n "${OS_PROJECT_NAME+x}" ]]; then
            OS_PROJECT_ID="$(openstack project show "$OS_PROJECT_NAME" -f value -c id)"
        else
            errorf 'Neither OS_PROJECT_ID nor OS_PROJECT_NAME are set'
            exit 1
        fi
    fi
    # Remove floating IPs and ports managed by the C&H LBaaS controller.
    # Those are annotated with a specific tag.
    # NOTE: this is racy, because the controller could be allocating a new port
    # we’re deleting it, but that’s just the same as above with the containers.
    # If it doesn’t work, we have to retry. By the time terraform fails deleting
    # the router (which is what is blocked by this operation), all instances are
    # already deleted, so the second run is guaranteed to succeed.
    IFS=$'\n' read -r -d '' -a floating_ip_ids < <( openstack floating ip list --project "$OS_PROJECT_ID" --any-tag 'cah-loadbalancer.k8s.cloudandheat.com/managed' -f value -c ID && printf '\0' )
    if [ "${#floating_ip_ids[@]}" != 0 ]; then
        run openstack floating ip delete "${floating_ip_ids[@]}"
    fi

    IFS=$'\n' read -r -d '' -a port_ids < <( openstack port list --project "$OS_PROJECT_ID" --any-tag 'cah-loadbalancer.k8s.cloudandheat.com/managed' -f value -c ID && printf '\0' )
    if [ "${#port_ids[@]}" != 0 ]; then
        run openstack port delete "${port_ids[@]}"
    fi

    IFS=$'\n' read -r -d '' -a volume_ids < <( openstack volume list --project "$OS_PROJECT_ID" -f value -c ID && printf '\0' )
    if [ "${#volume_ids[@]}" != 0 ]; then
        run openstack volume delete "${volume_ids[@]}"
    fi

    # only take the interface down if (a) wg_conf is set and (b) it exists.
    # it not existing can be the case if the cluster is being destroyed
    # before the end of stage 2.
    if [ -n "${wg_conf:-}" ] && [ -e "${wg_conf}" ]; then
        run wg-quick down "$wg_conf"
    fi

    destroy_terraform
}

function destroy_baremetal() {
    install_prerequisites

    "$actions_dir/update-inventory.sh" ansible

    pushd "$ansible_k8s_core_dir"
    # Include k8s-core roles
    ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles" \
    ansible_playbook -i "$ansible_inventory_host_file" \
    "destroy.yaml"
    popd
}


if [ "${tf_usage:?}" == 'false' ]; then
    destroy_baremetal
elif [ "${on_openstack:?}" == 'true' ]; then
    destroy_openstack
elif [ "${on_proxmox:?}" == 'true' ]; then
    destroy_proxmox
else
    errorf "Unsupported platform"
fi
