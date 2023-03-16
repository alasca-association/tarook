#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

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

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

# Installing updates can be highly disruptive
require_disruption

export KUBECONFIG="$cluster_repository/inventory/.etc/admin.conf"
cd "$ansible_k8s_base_playbook"
# include k8s-base roles
ANSIBLE_ROLES_PATH="$ansible_k8s_base_playbook/roles:$ansible_k8s_sl_playbook/roles" \
    ansible_playbook -i "$ansible_inventoryfile_03" migrate-docker-to-containerd.yaml \
    -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
    -e "ksl_vars_directory=$ansible_k8s_sl_vars_base"
