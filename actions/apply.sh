#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

"$actions_dir/apply-stage2.sh"
"$actions_dir/apply-stage3.sh"
"$actions_dir/apply-stage5.sh"

if [ "${K8S_CUSTOM_STAGE_USAGE:-false}" == 'true' ]; then
  "$actions_dir/apply-custom.sh"
fi

"$actions_dir/test.sh"
