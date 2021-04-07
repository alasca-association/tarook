#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

"$actions_dir/wg-up.sh"

cd "$ansible_playbook"
ansible-galaxy install -r requirements.yaml
ansible_playbook -i "$ansible_inventoryfile_03" 03_final.yaml
ansible_playbook -i "$ansible_inventoryfile_03" -t ksl-config -t kms-config 03_z_export_config.yaml
export KUBECONFIG="$cluster_repository/inventory/.etc/admin.conf"
pushd "$ansible_k8s_sl_playbook"
ansible_playbook -i "inventory/default.yaml" -e "@$cluster_repository/inventory/.etc/ksl.json" install.yaml
popd
pushd "$ansible_k8s_ms_playbook"
ansible_playbook -i "inventory/default.yaml" -i "$ansible_inventoryfile_03" -e "@$cluster_repository/inventory/.etc/kms.json" install.yaml
popd
