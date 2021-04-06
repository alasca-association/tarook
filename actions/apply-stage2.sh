#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if [ -d "$ansible_inventory_base" ]; then
    if [ ! -f "$ansible_inventoryfile_03" ]; then
        cp --no-clobber "$ansible_inventoryfile_02" "$ansible_inventoryfile_03"
        cp --no-clobber -r "$ansible_inventory_host_vars_dir_02/" "$ansible_inventory_dir_03"
        cp --no-clobber "$ansible_inventory_group_vars_dir_02/gateways/config.json" "$ansible_inventory_group_vars_dir_03/all/config_02_gateways.json"
    fi
fi

cd "$ansible_playbook"
ansible-galaxy install -r requirements.yaml
ansible_playbook -i "$ansible_inventoryfile_02" 02_trampoline.yaml "$@"
