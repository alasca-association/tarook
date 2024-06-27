#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

find "${actions_dir}/migrations" -type f -executable | sort | xargs -I {} sh -c '{}'
