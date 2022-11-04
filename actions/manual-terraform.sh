#!/bin/bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

cd "$terraform_state_dir"
export TF_DATA_DIR="$terraform_state_dir/.terraform"
exec terraform -chdir="$terraform_module" "$@"
