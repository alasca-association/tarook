#!/bin/bash

# -E to inherit trap into function calls
set -eEuo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

cd "$ansible_playbook"

# see lib.sh
trap do_cleanup_test_on_failure ERR

# Test k8s-service-layer
pushd "$ansible_k8s_sl_playbook"
ansible_playbook -i "inventory/default.yaml" -e "ksl_vars_directory=$ansible_k8s_sl_vars_base" test.yaml
popd

# Test k8s-managed-service layer
pushd "$ansible_k8s_ms_playbook"
ansible_playbook -i "inventory/default.yaml" -i "$ansible_inventoryfile_03" -e "kms_vars_directory=$ansible_k8s_ms_vars_base" test.yaml
popd

# Test k8s-base
# shellcheck disable=2086
ansible_playbook -i "$ansible_inventoryfile_03" -e "ksl_vars_directory=$ansible_k8s_sl_vars_base" \
    -e "ksl_playbook_directory=$ansible_k8s_sl_playbook" \
    -e "kms_vars_directory=$ansible_k8s_ms_vars_base" 04_tests.yaml
