#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

"$actions_dir/apply-stage2.sh"
"$actions_dir/apply-stage3.sh"

"$actions_dir/test.sh"
