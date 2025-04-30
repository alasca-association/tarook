#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

function usage() {
    echo "usage: $0 target" >&2
    echo >&2
    echo "Arguments:" >&2
    echo "    target" >&2
    echo "        Possible values include: conf_vars, vault, terraform, ansible" >&2
}

arg_num=1
if [ "$#" -lt "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo
    usage
    echo >&2
    exit 2
fi

target="$1"
shift

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
out=$(nix build --override-input yk8s "$code_repository" --print-out-paths --no-link "$@" ".#yk8s-outputs-$target")
# shellcheck disable=SC1091
. "$out/.path-info"
# shellcheck disable=SC2154
rsync -rL --chmod 664 "$out/$state" .
git add state
# shellcheck disable=SC2154
if [ "$inventory" != "" ]; then
    rm -rf "$inventory"
    mkdir -p "$inventory"
    rsync -rl --chmod 664 "$out/$inventory/" "$inventory"
fi
