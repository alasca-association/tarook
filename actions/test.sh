#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"
load_conf_vars

check_conf_sanity

check_venv

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

# Test all
pushd "$ansible_k8s_supplements_dir"
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles/:$ansible_k8s_supplements_dir/test-roles:$ansible_k8s_supplements_dir/roles/" \
    ansible_playbook -i "$ansible_inventory_host_file" \
    -e "ansible_k8s_core_dir=$ansible_k8s_core_dir" \
    test.yaml "$@"
popd
