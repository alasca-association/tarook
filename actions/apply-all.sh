#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

load_conf_vars

check_venv

set_kubeconfig

# Invoke Terraform, if configured
if [ "${tf_usage:-true}" == 'true' ]; then
  run "$actions_dir/apply-terraform.sh"
fi

# Prepare Gateways, if configured
if [ "${tf_usage:-true}" == 'true' ]; then
  run "$actions_dir/apply-prepare-gw.sh"
fi

# Invoke whole k8s-supplements (including k8s-core)
run "$actions_dir/apply-k8s-supplements.sh"

# Invoke custom stage if it exists
if [ -f "$ansible_k8s_custom_playbook" ]; then
  run "$actions_dir/apply-custom.sh"
fi
