#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=ci/scripts/lib.sh
. "$(dirname "$0")/lib.sh"

run nix build --no-link .#referenceOptionsRST
out="$(nix build --print-out-paths --no-link .#referenceOptionsRST)"
DIFF_PATH=./docs/user/reference/options
run rsync -rL --delete --chmod 664 "$out/" "${DIFF_PATH}"
export COMMIT_MSG="Update rendered docs"
push_if_changed
