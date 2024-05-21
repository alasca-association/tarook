#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

load_conf_vars

if [ "${tf_usage:-true}" == 'true' ]; then
  notef "Temporarily patching the Terraform module \
to unignore allowed_address_pairs..."
  if git -C "${code_repository}" apply --check --reverse \
"$(realpath --no-symlinks --relative-to="${code_repository}" "$actions_dir")\
/release-migrations/v10-00-tf-unignore-allowed_address_pairs.patch"
  then
    notef "Terraform module already got patched"
  else
    git -C "${code_repository}" apply \
"$(realpath --no-symlinks --relative-to="${code_repository}" "$actions_dir")\
/release-migrations/v10-00-tf-unignore-allowed_address_pairs.patch"
    notef "Terraform module patched"
  fi

  notef "Triggering Terraform (1/2)"
  run "$actions_dir/apply-terraform.sh"
  run "$actions_dir/update-inventory.sh"
fi
