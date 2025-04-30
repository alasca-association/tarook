#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

load_conf_vars

if [ "${tf_usage:-true}" == 'true' ]; then
  notef "Reverting temporarily patched Terraform module..."
  git -C "${code_repository}" apply --reverse \
    "$(realpath --no-symlinks --relative-to="${code_repository}" "$actions_dir")\
/release-migrations/v10-00-tf-unignore-allowed_address_pairs.patch"

  notef "Triggering Terraform (2/2)"
  run "$actions_dir/apply-terraform.sh"
  run "$actions_dir/update-inventory.sh" ansible

  # After enabling port security with Terraform
  # the cluster nodes will be unreachable for a short period of time.
  # Migration can only continue afterwards.
  notef "Checking that the Kubernetes API is reachable (timeout=4s)..."
  until (kubectl --request-timeout=4s api-versions &>/dev/null); do
    echo "Failed, retrying in 4s..."
    sleep 4
  done
  echo "Kubernetes API is reachable. Continuing..."
fi
