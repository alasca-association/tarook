#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

check_venv

require_harbour_disruption
require_ansible_disruption

if [ "$("$actions_dir/helpers/semver2.sh" "$(tofu -v -json | jq -r '.terraform_version')" "$tofu_min_version")" -lt 0 ]; then
    errorf 'Please upgrade OpenTofu to at least v'"$tofu_min_version"
    exit 5
fi

load_gitlab_vars

IFS=$'\n'
if [ "${MANAGED_K8S_NUKE_FROM_ORBIT:-}" = 'true' ]; then
    if [ "$(jq -r .backend.type "$tofu_state_dir/.terraform/terraform.tfstate")" == 'http' ] ; then
        container_id="$(curl -s --header "Private-Token: $TF_HTTP_PASSWORD" "$backend_address" | jq -r '((.resources | map(select(.name == "thanos_data" and .type == "openstack_objectstorage_container_v1")) | first).instances | first).attributes.id')"
    else
        container_id="$(jq -r '((.resources | map(select(.name == "thanos_data" and .type == "openstack_objectstorage_container_v1")) | first).instances | first).attributes.id' "$tofu_state_dir/terraform.tfstate")"
    fi
    if [ "x$container_id" != 'xnull' ]; then
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
# If it doesn’t work, we have to retry. By the time OpenTofu fails deleting
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

cd "$tofu_state_dir"
export TF_DATA_DIR="$tofu_state_dir/.terraform"
run tofu -chdir="$tofu_module" init
# The following task will fail if a) thanos wrote data into a container and b) `MANAGED_K8S_NUKE_FROM_ORBIT` is not set
run tofu -chdir="$tofu_module" destroy --var-file="$tofu_state_dir/config.tfvars.json" --auto-approve || true

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

# Purge wireguard keys of the gateway to ensure re-creation on new setup.
# Otherwise the playbook would load the same keys.
rm -f inventory/.etc/wg_gw_priv.key
rm -f inventory/.etc/wg_gw_pub.key

# Remove the tf_statefile from gitlab
if [ "$(jq -r .backend.type "$tofu_state_dir/.terraform/terraform.tfstate")" == 'http' ] ; then
    GITLAB_RESPONSE=$(curl -Is --header "Private-Token: $TF_HTTP_PASSWORD" -o "/dev/null" -w "%{http_code}" --request DELETE "$backend_address")
    check_return_code "$GITLAB_RESPONSE"
    rm -f "$tofu_module/backend_override.tf"
fi

# Purge the remaining tofu directory. Its existence is a condition for additional disruption checks.
rm -f "$tofu_state_dir/config.tfvars.json"
