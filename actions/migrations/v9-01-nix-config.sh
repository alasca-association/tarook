#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# migration to Nix based config

pushd "$cluster_repository" >/dev/null || exit 1

config_default="config/default.nix"

if [[ -f "inventory/yaook-k8s/hosts" ]] && \
    ! tomlq --exit-status '.terraform | if has ("enabled") then .enabled else true end' "config/config.toml" >/dev/null;
then
    echo "Migrating manual hosts file..."
    run git mv inventory/yaook-k8s/hosts config/hosts
    echo Done.
    echo
fi

if ! [[ -e "$config_default" ]]; then
    echo "Converting config..."
    cat <<EOF > "$config_default"
{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
in {
  yk8s = {
      # A reference for all available options can be found at
      # https://yaook.gitlab.io/k8s/devel/user/reference/options/index.html
EOF
    if [[ -e config/hosts ]]; then
        echo "miscellaneous.hosts_file = ./hosts;" >> "$config_default"
    fi
    tomlq -s '.[0] * .[1]' "$actions_dir/migrations/v9-01-default.toml" "config/config.toml" \
        | nix run github:cloudandheat/json2nix -- --strip-outer-bracket >> "$config_default"
    printf "};}" >> "$config_default"
    nix run nixpkgs#alejandra "$config_default" &>/dev/null
    rm config/config.toml
    echo "Done."
    echo
fi

echo "Rolling out Nix template..."
nix_output="$(nix flake init -t "${code_repository}#cluster-repo" 2>&1 || true)"
nix_output="$(echo "$nix_output" | grep -vE 'error: Encountered [0-9]+ conflicts')" # We accept that some files already exist
echo "$nix_output"
echo
if echo "$nix_output" | grep -q error; then
    errorf "Error during nix flake init"
    exit 1
fi

run git add flake.nix config/default.nix

if [[ -e "config/wireguard_ipam.toml" ]]; then
    echo "Migrating wireguard state..."
    run mkdir -p state/wireguard
    run git mv config/wireguard_ipam.toml state/wireguard/ipam.toml
    echo "Done."
    echo
fi

if [[ -d terraform ]]; then
    echo "Migrating terraform state..."
    run mkdir -p state
    run git mv terraform state/terraform
    echo "Done."
    echo
fi

tf_meta_state=state/terraform/.terraform/terraform.tfstate
if [[ -e "$tf_meta_state" ]] && \
    jq -e '.backend.type == "local"' "$tf_meta_state" >/dev/null
then
    echo "Fixing terraform local backend path..."
    jq '.backend.config.path = "../../state/terraform/terraform.tfstate"' "$tf_meta_state" | sponge "$tf_meta_state"
    echo "Done."
    echo
fi

if [[ -d vault ]]; then
    echo "Migrating vault state..."
    run mkdir -p state
    run git mv vault state/vault
    echo "Done."
    echo
fi

run rm -rf inventory

echo
echo "Migration done!"

echo "Building inventory..."
run "$actions_dir/update-inventory.sh"

popd >/dev/null || exit 1
