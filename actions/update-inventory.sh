#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Available targets
declare -a targets=("conf_vars" "vault" "terraform" "ansible")

# print help message
function helpf() {
  action_name=${0##*/}
  printf "%s - Action Script to update the Cluster Inventory\n\n" "$action_name"
  printf "Usage: %s [list|help] <target>\n\n" "$action_name"
  printf "Arguments:\n"
  printf "list       List available targets\n"
  printf "help       Print this help message\n"
  printf "<target>   Update inventory for specific target\n"
}

# Check for valid number of arguments
arg_num=1
if [ "$#" -ne "$arg_num" ]; then
    errorf "ERROR: Expecting $arg_num argument(s), but $# were given"
    echo
    helpf
    exit 2
fi

# Verify supplied argument
target="$1"
if [ "$target" == "list" ]; then
  printf "Possible targets are:\n"
  printf ' %s\n' "${targets[@]}"
  exit 0
fi
if [ "$target" == "help" ]; then
  helpf
  exit 0
fi

shift

check_release_migration_lock

if [[ -e "inventory/yaook-k8s/hosts" ]] && [[ ! -L "inventory/yaook-k8s/hosts" ]]; then
    errorf "ERROR: Found legacy inventory. Aborting."
    errorf "Please make sure that all manual changes to the inventory (eg. hosts file)"
    errorf "are persisted in the configuration, then delete the inventory directory"
    errorf "and add it to .gitignore".
    exit 1
fi

# Check if target is valid
# shellcheck disable=SC2068
for i in ${targets[@]}; do
  if [[ "$i" == "$target" ]]; then
    valid_target=true
  fi
done
if [ -z "${valid_target:-}" ]; then
  errorf "$target is not a valid target\n" >&2
  helpf
  exit 2
fi

if [[ -e "state" ]]; then git add state; fi
if [ -z "${TAROOK_NIX_FLAGS:-}" ]; then
    out=$(nix build --override-input yk8s "$code_repository" --print-out-paths --no-link "$@" ".#yk8s-outputs-$target")
else
    out=$(nix build --override-input yk8s "$code_repository" --print-out-paths --no-link "${TAROOK_NIX_FLAGS}" "$@" ".#yk8s-outputs-$target")
fi
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
