#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

AVARS=""
for var_file in "$ansible_k8s_ms_vars_base"/*.yaml
do
    AVARS="${AVARS} -e @$var_file"
done

export KUBECONFIG="$cluster_repository/inventory/.etc/admin.conf"
cd "$ansible_k8s_ms_playbook"
# shellcheck disable=2086
ansible_playbook -i "inventory/default.yaml" -i "$ansible_inventoryfile_03" $AVARS install.yaml
