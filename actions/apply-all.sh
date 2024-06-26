#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

check_venv

# # Invoke Terraform, if configured
# if [ "${TF_USAGE:-true}" == 'true' ]; then
#   run "$actions_dir/apply-terraform.sh"
# fi

# # Prepare Gateways, if configured
# if [ "${TF_USAGE:-true}" == 'true' ]; then
#   run "$actions_dir/apply-prepare-gw.sh"
# fi

kubectl get nodes

kubectl get secrets

kubectl config current-context

exit 1

# Invoke whole k8s-supplements (including k8s-core)
run "$actions_dir/apply-k8s-supplements.sh"

# Invoke custom stage
if [ "${K8S_CUSTOM_STAGE_USAGE:-true}" == 'true' ]; then
  run "$actions_dir/apply-custom.sh"
fi
