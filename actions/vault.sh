#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Create vault folders
# shellcheck disable=SC2154
mkdir -p "$vault_dir/config"
mkdir -p "$vault_dir/data"
cd "$vault_dir"

# Copy Vault config template
cp --no-clobber "$code_repository/templates/config.template.hcl" "$vault_dir/config/config.hcl"

# TLS certificate creation
if [ ! -f "$vault_dir/tls/vault.crt" ]; then
    export cluster_repository
    export vault_container_name
    "$code_repository/actions/vault_ssl.sh"
fi

# Get Vault container status
vault_status="$(docker inspect -f '{{.State.Status}}' "$vault_container_name" 2>/dev/null || true)"

# Create Vault container
if [ -z "$vault_status" ]; then
    run docker run -d \
        --name "$vault_container_name" \
        -p 8200 \
        --cap-add=IPC_LOCK \
        -v "$vault_dir/config":/vault/config \
        -v "$vault_dir/tls":/vault/tls \
        -e VAULT_ADDR="https://127.0.0.1:8200" \
        -e VAULT_CACERT="/vault/tls/ca/vaultca.crt" \
        vault:1.9.3 server
elif [ "$vault_status" = "exited" ]; then
    run docker start "$vault_container_name" > /dev/null
fi

vault_initialized=false

# Get Vault initialization status and loop until Vault is initialized
# shellcheck disable=SC2034
for attempt in $(seq 1 60) ; do
    vault_init_status="$( (docker exec "$vault_container_name" vault status --format=json 2>/dev/null || true) | jq -r .initialized)"
    printf "Initialization status: %s\n" "$vault_init_status"
    
    if [ "$vault_init_status" = "false" ]; then
        docker exec "$vault_container_name" vault operator init -key-shares=1 -key-threshold=1 -format=json >"$vault_dir/init.out" || true
        vault_initialized=true
    fi
    if [ "$vault_init_status" = "true" ]; then
        printf "\nVault has been initialized 🔐\n"
        vault_initialized=true
        break
    fi
    printf "Vault is being initialized. Please wait.. ⏳\n"
    sleep 1
done
if [ "$vault_initialized" = "false" ]; then
    printf "🚨 \nVault couldn\'t be initialized! 🚨" >&2
    exit 2
fi

# Get Vault sealed status, unseal Vault and write root token into file
vault_sealed_status="$( (docker exec "$vault_container_name" vault status --format=json || true) | jq -r .sealed)"

if [ "$vault_sealed_status" = "true" ]; then
    VAULT_UNSEAL_KEY="$(jq .unseal_keys_b64[0] -c "$vault_dir/init.out" -r | tee "$vault_dir/unseal.key")"
    docker exec "$vault_container_name" vault operator unseal "$VAULT_UNSEAL_KEY" >/dev/null
    printf "Vault has been unsealed 🔓 ✅\n"
fi

jq ".root_token" "$vault_dir/init.out" -r >"$vault_dir/root.key"