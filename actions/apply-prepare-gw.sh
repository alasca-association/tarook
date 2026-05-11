#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" conf_vars

load_conf_vars

check_venv


require_vault_token

install_prerequisites

if [ "${gateway_nodes_configured:-true}" == 'false' ]; then
  errorf "No gateways are configured."
  exit 1
fi

"$actions_dir/update-inventory.sh" ansible

# Prepare Gateways, if configured
pushd "$ansible_k8s_supplements_dir"
# Include k8s-core common roles
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles:$ansible_k8s_supplements_dir/roles" \
  ansible_playbook -i "$ansible_inventory_host_file" \
  -e "ansible_k8s_core_dir=$ansible_k8s_core_dir" \
  prepare-gw.yaml "$@"
popd
