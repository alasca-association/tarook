#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

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

# Installing updates can be highly disruptive
require_disruption

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

cd "$ansible_k8s_base_playbook"
ansible-galaxy install -r "$ansible_directory/requirements.yaml"
ANSIBLE_ROLES_PATH="$ansible_k8s_base_playbook/roles:$ansible_k8s_sl_playbook/roles" \
  ansible_playbook -i "$ansible_inventoryfile_02" \
  -i "$ansible_inventoryfile_03" \
  -e "ksl_vars_directory=$ansible_k8s_sl_vars_base" \
  -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
  system_update_nodes.yaml
