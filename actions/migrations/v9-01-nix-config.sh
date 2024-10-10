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
if [[ -d vault ]]; then
    mkdir -p state
    git mv vault state/vault
fi
if [[ -e "config/config.toml" ]]; then
    if git status -q | grep config.toml &>/dev/null; then
        errorf "config.toml is not comitted. Refusing to continue."
        exit 1
    fi

    cat config/default.nix.tpl <(nix run github:cloudandheat/json2nix#toml2nix config/config.toml) > config/default.nix
    rm -f config/config.toml
    git add config
fi
rm -f config/default.nix.tpl

popd >/dev/null || exit 1
