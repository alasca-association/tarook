#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

require_vault_token

pushd "$ansible_k8s_core_dir"
# Include k8s-core roles
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles" \
  ansible_playbook -i "$ansible_inventory_host_file" \
  k8s-login.yaml "$@"
popd
