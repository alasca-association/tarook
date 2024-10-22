#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# migration to Nix based config

pushd "$cluster_repository" >/dev/null || exit 1

echo "Rolling out Nix template"
nix_output="$(nix flake init -t "${code_repository}#migration" 2>&1 || true)"
nix_output="$(echo "$nix_output" | grep -vE 'error: Encountered [0-9]+ conflicts')" # We accept that some files may already exist
echo "$nix_output"
if echo "$nix_output" | grep -q error; then
    errorf "Error during nix flake init"
    exit 1
fi

git add flake.nix config/default.nix

if [[ -e "config/wireguard_ipam.toml" ]]; then
    echo "Migrating wireguard state"
    mkdir -p state/wireguard
    git mv config/wireguard_ipam.toml state/wireguard/ipam.toml
fi

if [[ -d terraform ]]; then
    echo "Migrating terraform state"
    mkdir -p state
    git mv terraform state/terraform
fi

if [[ -d vault ]]; then
    echo "Migrating vault state"
    mkdir -p state
    git mv vault state/vault
fi

if [[ -f "inventory/yaook-k8s/hosts" ]] && \
    ! tomlq --exit-status '.terraform | if has ("enabled") then .enabled else true end' "config/config.toml" >/dev/null;
then
    git mv inventory/yaook-k8s/hosts config/hosts
    echo ""
    echo "Attention:"
    echo "Manual hosts file detected. Please add"
    echo "miscellaneous.hosts_file = ./hosts;"
    echo "to config/default.nix"
fi

rm -rf inventory

echo ""
echo "Migration done!"

popd >/dev/null || exit 1
