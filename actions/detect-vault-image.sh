#!/usr/bin/env bash
# This script is separate so that we can invoke it in the CI, without having
# to invoke vault.sh (vault.sh is tricky to run in the CI because it requires
# docker). We want to have the image version detection well-tested in CI
# because it is easy to break accidentally.
set -euo pipefail
gitlab_ci_file="$(dirname "$0")/../ci/cluster-tests.yaml"
# shellcheck disable=SC2016
exec grep -Po '(?<=\${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/)hashicorp/vault:\S+(?=")' "$gitlab_ci_file"
