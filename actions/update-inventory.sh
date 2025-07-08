#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

check_release_migration_lock

if [[ -e "inventory/yaook-k8s/hosts" ]] && [[ ! -L "inventory/yaook-k8s/hosts" ]]; then
    echo ""
    echo "ERROR: Found legacy inventory. Aborting."
    echo "Please make sure that all manual changes to the inventory (eg. hosts file)"
    echo "are persisted in the configuration, then delete the inventory directory"
    echo "and add it to .gitignore".
    exit 1
fi
if [[ -e "state" ]]; then git add state; fi
if [ -z "${TAROOK_NIX_FLAGS:-}" ]; then
    out=$(nix build --override-input yk8s "$code_repository" --print-out-paths --no-link "$@" .#yk8s-outputs)
else
    out=$(nix build --override-input yk8s "$code_repository" --print-out-paths --no-link "${TAROOK_NIX_FLAGS}" "$@" .#yk8s-outputs)
fi

rsync -rL --chmod 664 "$out/state" .
rm -rf inventory
mkdir -p inventory/yaook-k8s/
rsync -rl --chmod 664 "$out/inventory/yaook-k8s/" inventory/yaook-k8s/
git add state
