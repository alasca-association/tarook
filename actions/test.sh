#!/bin/bash

# -E to inherit trap into function calls
set -eEuo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

"$actions_dir/wg-up.sh"

cd "$ansible_playbook"

# see lib.sh
trap do_cleanup_test_on_failure ERR

ansible_playbook -i "$ansible_inventoryfile_03" 04_tests.yaml
ansible_playbook -i "$ansible_inventoryfile_03" -t ksl-config -t kms-config 03_z_export_config.yaml
pushd "$ansible_k8s_sl_playbook"
ansible_playbook -i "inventory/default.yaml" -e "@$cluster_repository/inventory/.etc/ksl.json" test.yaml
popd
pushd "$ansible_k8s_ms_playbook"
ansible_playbook -i "inventory/default.yaml" -i "$ansible_inventoryfile_03" -e "@$cluster_repository/inventory/.etc/kms.json" test.yaml
popd
