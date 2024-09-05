#!/usr/bin/env bash

# We must update keepalived configuration

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

notef "Updating keepalived configuration."
AFLAGS="--diff -t keepalived" run "$actions_dir/apply-k8s-core.sh" install-frontend-services.yaml
