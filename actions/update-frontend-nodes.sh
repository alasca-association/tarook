#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" conf_vars

load_conf_vars


check_venv
reload_lazy_env

require_ansible_disruption

while getopts s flag
do
    case "${flag}" in
        s)
            k8s_skip_upgrade_checks=true
            ;;
        *)
            echo "Unknown flag passed: '${flag}'" >&2
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))

install_prerequisites

# Bring the wireguard interface up if configured so
if [ "${wg_usage:?}" == "true" ]; then
    "$actions_dir/wg-up.sh"
fi

set_kubeconfig

"$actions_dir/update-inventory.sh" ansible

# Trigger whole LCM
pushd "$ansible_k8s_core_dir"
# Include k8s-core roles
ansible_playbook -i "$ansible_inventory_host_file" \
  -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
  update-frontend-nodes.yaml "$@"
popd
