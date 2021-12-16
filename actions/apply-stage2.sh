#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

cd "$ansible_k8s_base_playbook"
ansible-galaxy install -r "$ansible_directory/requirements.yaml"
ansible_playbook -i "$ansible_inventoryfile_02" install_frontend.yaml "$@"
