#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

pushd "$cluster_repository" >/dev/null || exit 1

notef "Creating Terraform disruption lock"
touch "$terraform_disruption_lock"
git add "$terraform_disruption_lock"

popd >/dev/null || exit 1
