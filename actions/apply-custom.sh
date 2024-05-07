#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"
load_conf_vars

check_venv

require_vault_token

install_prerequisites

# Ensure that the latest config is deployed to the inventory
nix run .#update-inventory

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

# Make roles from all stages accessible
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles:$ansible_k8s_supplements_dir/roles:$ansible_k8s_custom_playbook/roles"
export ANSIBLE_ROLES_PATH

cd "$ansible_k8s_custom_playbook"
ansible_playbook -i "$ansible_inventory_host_file" \
  -e "ansible_k8s_core_dir=$ansible_k8s_core_dir" \
  main.yaml "$@"
