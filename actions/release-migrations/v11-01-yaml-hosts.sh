#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if [ "${tf_usage:-true}" == 'true' ]; then
    notef "Removing obsolete state files..."
    run git rm -rf "$terraform_state_dir/rendered"

    notef "Running Terraform stage to create output files"
    run "$actions_dir/apply-terraform.sh"
fi
