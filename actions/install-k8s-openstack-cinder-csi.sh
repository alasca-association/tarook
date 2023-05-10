#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

export KUBECONFIG="$cluster_repository/inventory/.etc/admin.conf"
cd "$ansible_k8s_base_playbook"
ansible-galaxy install -r "$ansible_directory/requirements.yaml"
ansible_playbook -i "$ansible_inventoryfile_03" install_k8s_openstack_cinder_csi.yaml "$@"
