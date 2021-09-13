#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"

if [ "${TF_USAGE:-true}" == 'true' ]; then
  "$actions_dir/apply-terraform.sh"
fi

"$actions_dir/apply-stage2.sh"
"$actions_dir/apply-stage3.sh"
"$actions_dir/apply-stage4.sh"
"$actions_dir/apply-stage5.sh"

"$actions_dir/test.sh"
