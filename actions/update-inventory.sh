#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

if [ "$("$actions_dir/helpers/semver2.sh" "$(nix --version | grep -Eo '[0-9]+\.[0-9]+.[0-9]+')" "2.23")" -gt 0 ]; then
    nix flake update yk8s
else
    nix flake lock --update-input yk8s
fi
if [[ -e "inventory/yaook-k8s/hosts" ]] && [[ ! -L "inventory/yaook-k8s/hosts" ]]; then
    echo ""
    echo "ERROR: Found legacy inventory. Aborting."
    echo "Please make sure that all manual changes to the inventory (eg. hosts file)"
    echo "are persisted in the configuration, then delete the inventory directory"
    echo "and add it to .gitignore".
    exit 1
fi
if [[ -e "state" ]]; then git add state; fi
out=$(nix build --print-out-paths --no-link .#yk8s-outputs)
rsync -rL --chmod 664 "$out/state" .
rm -rf inventory
mkdir -p inventory/yaook-k8s/
rsync -rl --chmod 664 "$out/inventory/yaook-k8s/" inventory/yaook-k8s/
git add state
