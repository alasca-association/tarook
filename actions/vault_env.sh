#!/usr/bin/env bash
flags=$(shopt -po)
set -euo pipefail

actions_dir="$(pwd)/managed-k8s/"

# shellcheck source=actions/lib.sh
. "$actions_dir/actions/lib.sh"

# attempt to start vault right away
if ! "$actions_dir/actions/vault.sh"; then
    echo "Failed to ensure vault is up & running.."
    echo "Still preparing your environment as good as I can"
fi

# now vault should be running, but we cannot fully rely on it (hence some error
# handling down below)

VAULT_URL_ADDR="https://127.0.0.1"
# shellcheck disable=SC2154
VAULT_CACERT="$vault_dir/tls/ca/vaultca.crt"
export VAULT_CACERT

VAULT_CLIENT_VERSION="$(vault --version)"
if ! VAULT_SERVER_VERSION="$(docker exec "$vault_container_name" vault status --format=json | jq -r .version)"; then
    VAULT_SERVER_VERSION="unknown"
fi

VAULT_PORT="$(docker inspect -f '{{(index (index .NetworkSettings.Ports "8200/tcp") 0).HostPort}}' "$vault_container_name")"
export VAULT_PORT

VAULT_TOKEN="$(cat "$vault_dir/root.key")"
export VAULT_TOKEN

VAULT_ADDR="$VAULT_URL_ADDR:$VAULT_PORT"
export VAULT_ADDR

echo "---------------------------------------------------------------------------------"
echo "Vault Info"
echo ""
echo "Vault Client Version:     $VAULT_CLIENT_VERSION"
echo "Vault Server Version:     $VAULT_SERVER_VERSION"
echo ""
echo "Address:                  $VAULT_ADDR"
echo "CA Certificate:           $VAULT_CACERT"
echo "Root Token:               $VAULT_TOKEN"
echo "---------------------------------------------------------------------------------"

# Restore shell options
eval "$flags"
