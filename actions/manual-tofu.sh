#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

cd "$tofu_state_dir"
export TF_DATA_DIR="$tofu_state_dir/.terraform"
exec tofu -chdir="$tofu_module" "$@"
