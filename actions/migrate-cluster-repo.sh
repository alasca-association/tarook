#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if [[ "$(git status --short | grep --count --invert-match --extended-regexp 'managed-k8s|submodules')" -ne 0 ]]; then
    errorf "Cluster repository not clean. Refusing to run migration"
    exit 1
fi

find "${actions_dir}/migrations" -type f -executable | sort | xargs -I {} sh -c '{}'
