#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

require_disruption

IFS=$'\n'
if [ "x${MANAGED_K8S_NUKE_FROM_ORBIT:-}" = 'xtrue' ]; then
    container_id="$(jq -r '((.resources | map(select(.name == "thanos_data" and .type == "openstack_objectstorage_container_v1")) | first).instances | first).attributes.id' "$terraform_state_dir/terraform.tfstate")"
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

# Remove floating IPs and ports managed by the C&H LBaaS controller.
# Those are annotated with a specific tag.
# NOTE: this is racy, because the controller could be allocating a new port
# we’re deleting it, but that’s just the same as above with the containers.
# If it doesn’t work, we have to retry. By the time terraform fails deleting
# the router (which is what is blocked by this operation), all instances are
# already deleted, so the second run is guaranteed to succeed.
IFS=$'\n' read -r -d '' -a floating_ip_ids < <( openstack floating ip list --any-tag 'cah-loadbalancer.k8s.cloudandheat.com/managed' -f value -c ID && printf '\0' )
if [ "${#floating_ip_ids[@]}" != 0 ]; then
    run openstack floating ip delete "${floating_ip_ids[@]}"
fi

IFS=$'\n' read -r -d '' -a port_ids < <( openstack port list --any-tag 'cah-loadbalancer.k8s.cloudandheat.com/managed' -f value -c ID && printf '\0' )
if [ "${#port_ids[@]}" != 0 ]; then
    run openstack port delete "${port_ids[@]}"
fi

cd "$terraform_state_dir"
run terraform init "$terraform_module"
run terraform destroy --var-file=./config.tfvars.json --auto-approve "$terraform_module"

IFS=$'\n' read -r -d '' -a volume_ids < <( openstack volume list -f value -c ID && printf '\0' )
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
