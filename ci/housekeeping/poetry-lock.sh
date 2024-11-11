#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=ci/housekeeping/lib.sh
. "$(dirname "$0")/lib.sh"

poetry lock --no-update
DIFF_PATH=./poetry.lock
COMMIT_MSG="auto fixes for poetry.lock"
push_if_changed
