#!/bin/bash
flags=$(shopt -po)
set -euo pipefail

actions_dir="$(pwd)/managed-k8s/"

# shellcheck disable=SC1091
. "$actions_dir/actions/lib.sh"

VAULT_STATUS="$(docker inspect -f '{{.State.Status}}' "$vault_container_name" 2>/dev/null || true)"

if [ "$VAULT_STATUS" = "running" ]; then

    VAULT_URL_ADDR="https://127.0.0.1"
    # shellcheck disable=SC2154
    VAULT_CACERT="$vault_dir/tls/ca/vaultca.crt"
    export VAULT_CACERT

    VAULT_CLIENT_VERSION="$(vault --version)"
    VAULT_SERVER_VERSION="$(docker exec "$vault_container_name" vault status --format=json | jq -r .version)"

    VAULT_PORT="$(docker inspect -f '{{(index (index .NetworkSettings.Ports "8200/tcp") 0).HostPort}}' "$vault_container_name")"
    export VAULT_PORT

    VAULT_ROOT_TOKEN="$(cat "$vault_dir/root.key")"
    export VAULT_ROOT_TOKEN

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
    echo "Root Token:               $VAULT_ROOT_TOKEN"
    echo ""
    echo "Export VAULT_ADDR and VAULT_CACERT with the above infos and"
    echo "use 'vault login $VAULT_ROOT_TOKEN' to log in into Vault."
    echo "---------------------------------------------------------------------------------"
elif [ "$VAULT_STATUS" = "exited" ]; then
    echo "The YAOOK Vault container was created but is down."
else
    echo "The YAOOK Vault container couldn't be found or has not been created yet."
fi

# Restore shell options
eval "$flags" 
