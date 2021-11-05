#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

# Make roles from all stages accessible
ANSIBLE_ROLES_PATH="$ansible_k8s_base_playbook/roles:$ansible_k8s_sl_playbook/roles:$ansible_k8s_ms_playbook/roles:$ansible_k8s_custom_playbook/roles"
export ANSIBLE_ROLES_PATH

cd "$ansible_k8s_custom_playbook"
ansible_playbook -i "$ansible_inventoryfile_custom" main.yaml "$@"
