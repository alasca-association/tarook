#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Bring the wireguard interface up
if [ "${WG_USAGE,,:true}" ]; then
    "$actions_dir/wg-up.sh"
fi

cd "$ansible_playbook"
ansible-galaxy install -r requirements.yaml
ansible_playbook -i "$ansible_inventoryfile_03" 03_k8s_base.yaml "$@"
