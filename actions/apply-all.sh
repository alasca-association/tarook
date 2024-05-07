#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# Ensure that the latest config is deployed to the inventory
nix run .#update-inventory

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"
load_conf_vars

check_venv

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
if [ -f "$ansible_k8s_custom_playbook/main.yaml" ]; then
  run "$actions_dir/apply-custom.sh"
fi
