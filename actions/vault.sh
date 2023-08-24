#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

vault_image="$(bash "$actions_dir/detect-vault-image.sh")"

# Create vault folders
# shellcheck disable=SC2154
mkdir -p "$vault_dir/config"
mkdir -p "$vault_dir/data"
cd "$vault_dir"

# Copy Vault config template; don't overwrite (--no-clobber); check for existence to avoid stopping here
# Coreutils v9.2 changed the behaviour of --no-clobber[1].
# [1] https://github.com/coreutils/coreutils/blob/df4e4fbc7d4605b7e1c69bff33fd6af8727cf1bf/NEWS#L88
if [ ! -f "$vault_dir/config/config.hcl" ]; then
    cp --no-clobber "$code_repository/templates/config.template.hcl" "$vault_dir/config/config.hcl"
fi

# TLS certificate creation
if [ ! -f "$vault_dir/tls/vault.crt" ]; then
    export cluster_repository
    export vault_container_name
    "$code_repository/actions/vault_ssl.sh"
fi

# Get Vault container status
vault_status="$(docker inspect -f '{{.State.Status}}' "$vault_container_name" 2>/dev/null || true)"

# Create Vault container
if [ -z "$vault_status" ] || [ "$vault_status" = 'exited' ]; then
    # always upgrade vault when it's not running
    run docker rm -f "$vault_container_name" >/dev/null || true
    if [ "${VAULT_IN_DOCKER_USE_ROOTLESS:-true}" = "true" ]; then
        run docker run \
            --name "${vault_container_name}-chown" \
            -v "$vault_dir/config":/vault/config \
            -v "$vault_dir/tls":/vault/tls \
            -v "$vault_dir/data":/vault/file \
            --rm \
            "$vault_image" chown -R "$(id -u):$(id -g)" /vault
    fi
    run docker run -d \
        --name "$vault_container_name" \
        -p 8200 \
        --cap-add=IPC_LOCK \
        -e SKIP_CHOWN=yes \
        -e SKIP_SETCAP=yes \
        -u "$(id -u):$(id -g)" \
        -v "$vault_dir/config":/vault/config \
        -v "$vault_dir/tls":/vault/tls \
        -v "$vault_dir/data":/vault/file \
        -e VAULT_ADDR="https://127.0.0.1:8200" \
        -e VAULT_CACERT="/vault/tls/ca/vaultca.crt" \
        "$vault_image" server
fi

vault_initialized=false

# Get Vault initialization status and loop until Vault is initialized
# shellcheck disable=SC2034
for attempt in $(seq 1 60) ; do
    vault_init_status="$( (docker exec "$vault_container_name" vault status --format=json 2>/dev/null || true) | jq -r .initialized)"
    printf "Initialization status: %s\n" "$vault_init_status"

    if [ "$vault_init_status" = "false" ]; then
        init_out="$(docker exec "$vault_container_name" vault operator init -key-shares=1 -key-threshold=1 -format=json)"
        jq .unseal_keys_b64[0] -cr <<<"$init_out" > "$vault_dir/unseal.key"
        jq ".root_token" -cr <<<"$init_out" >"$vault_dir/root.key"
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
    unseal_key="$(cat "$vault_dir/unseal.key")"
    docker exec "$vault_container_name" vault operator unseal "$unseal_key" >/dev/null
    printf "Vault has been unsealed 🔓 ✅\n"
fi
