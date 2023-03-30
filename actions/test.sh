#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

cd "$ansible_k8s_base_playbook"

# Required for the upper layer tests
export KUBECONFIG="$cluster_repository/inventory/.etc/admin.conf"

# Test k8s-base
# Please unclutter me
# shellcheck disable=2086
ANSIBLE_ROLES_PATH="$ansible_k8s_base_playbook/test-roles/" \
    ansible_playbook -i "$ansible_inventoryfile_03" \
    -i "$ansible_inventoryfile_02" \
    -e "ksl_vars_directory=$ansible_k8s_sl_vars_base" \
    -e "ksl_playbook_directory=$ansible_k8s_sl_playbook" \
    -e "kms_vars_directory=$ansible_k8s_ms_vars_base" \
    test.yaml
