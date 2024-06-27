#!/bin/bash
set -euo pipefail
actions_dir="$(cd "$(dirname "$0")/../.." && pwd)"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

arg_num=0
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

vault write "$nodes_approle_path/role/dev-orchestrator" \
    token_policies="$common_policy_prefix/orchestrator,default" >/dev/null

role_id="$(vault read -field=role_id "$nodes_approle_path/role/dev-orchestrator/role-id")"
secret_id="$(vault write -force -field secret_id "$nodes_approle_path/role/dev-orchestrator/secret-id")"

echo "export VAULT_AUTH_PATH=$nodes_approle_name"
echo "export VAULT_AUTH_METHOD=approle"
echo "export VAULT_ROLE_ID=$role_id"
echo "export VAULT_SECRET_ID=$secret_id"
