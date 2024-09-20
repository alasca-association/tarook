#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"
load_conf_vars

check_venv

check_conf_sanity

require_vault_token

install_prerequisites

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

set_kubeconfig

# Make roles from all stages accessible
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles:$ansible_k8s_supplements_dir/roles:$ansible_k8s_custom_playbook_dir/roles"
export ANSIBLE_ROLES_PATH

pushd "$ansible_k8s_custom_dispatch_dir"
ansible_playbook \
  -i "$ansible_inventory_host_file" \
  -i "$ansible_k8s_custom_inventory" \
  -e "ansible_k8s_core_dir=$ansible_k8s_core_dir" \
  -e "ansible_k8s_custom_playbook=$ansible_k8s_custom_playbook" \
  main.yaml "$@"
popd
