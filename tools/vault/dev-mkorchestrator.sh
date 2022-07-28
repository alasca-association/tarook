#!/bin/bash
set -euo pipefail
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

vault write "$nodes_approle_path/role/dev-orchestrator" \
    token_policies="$common_policy_prefix/orchestrator,default" >/dev/null

role_id="$(vault read -field=role_id "$nodes_approle_path/role/dev-orchestrator/role-id")"
secret_id="$(vault write -force -field secret_id "$nodes_approle_path/role/dev-orchestrator/secret-id")"

echo "export VAULT_AUTH_PATH=$nodes_approle_name"
echo "export VAULT_AUTH_METHOD=approle"
echo "export VAULT_ROLE_ID=$role_id"
echo "export VAULT_SECRET_ID=$secret_id"
