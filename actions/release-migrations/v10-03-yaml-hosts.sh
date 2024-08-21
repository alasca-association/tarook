#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

notef "Removing obsolete state files..."
run git rm -rf "$terraform_state_dir/rendered"
