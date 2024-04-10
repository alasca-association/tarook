#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

require_vault_token

install_prerequisites

if [ "${TF_USAGE:-true}" == 'false' ]; then
  errorf "It seems like you're not running on top of OpenStack,"
  errorf "because TF_USAGE is false."
  errorf "Gateways are OpenStack-specific and must not be prepared"
  errorf "for other use cases. You must not execute this action script."
  exit 1
fi

# Prepare Gateways, if configured
pushd "$ansible_k8s_supplements_dir"
# Include k8s-core common roles
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles:$ansible_k8s_supplements_dir/roles" \
  ansible_playbook -i "$ansible_inventory_host_file" \
  -e "ansible_k8s_core_dir=$ansible_k8s_core_dir" \
  prepare-gw.yaml "$@"
popd
