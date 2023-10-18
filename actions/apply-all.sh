#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Invoke Terraform, if configured
if [ "${TF_USAGE:-true}" == 'true' ]; then
  run "$actions_dir/apply-terraform.sh"
fi

# Prepare Gateways, if configured
if [ "${TF_USAGE:-true}" == 'true' ]; then
  run "$actions_dir/apply-prepare-gw.sh"
fi

# Invoke whole k8s-supplements (including k8s-core)
run "$actions_dir/apply-k8s-supplements.sh"

# Invoke custom stage
run "$actions_dir/apply-custom.sh"
