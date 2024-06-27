#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# migration to Nix based config

pushd "$cluster_repository" >/dev/null || exit 1

nix flake init -t "${code_repository}#migration"
git add flake.nix config/default.nix
if [[ -e "config/wireguard_ipam.toml" ]]; then
    mkdir -p state/wireguard
    git mv config/wireguard_ipam.toml state/wireguard/ipam.toml
fi
if [[ -d terraform ]]; then
    mkdir -p state
    git mv terraform state/terraform
fi
popd >/dev/null || exit 1
