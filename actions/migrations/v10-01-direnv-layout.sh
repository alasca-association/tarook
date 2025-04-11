#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

pushd "$cluster_repository" >/dev/null || exit 1

notef "Updating .envrc"
run sed -i 's#use flake_if_nix ./managed-k8s#layout yaook-k8s#g' .envrc
run sed -i '\#layout poetry#d' .envrc
run sed -i '\#source_env ~/.config/yaook-k8s/env || true#d' .envrc
run sed -i '\#source_env_if_exists ~/.config/yaook-k8s/env#d' .envrc
# shellcheck disable=SC2016
run sed -i '\#source_env "$PWD/.envrc.local" || true#d' .envrc
# shellcheck disable=SC2016
run sed -i '\#source_env_if_exists $PWD/.envrc.local#d' .envrc
run sed -i 's#\(source_env ./managed-k8s/.envrc.lib.sh\) || true#\1#' .envrc

run git add .envrc

popd >/dev/null || exit 1
