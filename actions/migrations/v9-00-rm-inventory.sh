#!/usr/bin/env bash

# Append new .gitignore from LCM to existing .gitignore of the
# cluster repository if they differ.
# Additionally, ensure inventory is removed from version control
# For further details, see issue #748

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

notef "Check if .gitignore has to be modified"
gitignore_cluster_repo="$cluster_repository/.gitignore"
gitignore_lcm_template="$code_repository/nix/templates/cluster-repo/.gitignore"
appendix_comment="#### Appended .gitignore from release v9.0.0 ####"
if ! cmp --silent "$gitignore_cluster_repo" "$gitignore_lcm_template"; then
  # for determinism, check if already appended
  if ! grep --silent "$appendix_comment" "$gitignore_cluster_repo"; then
    notef "Appending new .gitignore template of LCM to existing one"
    echo "$appendix_comment" >> "$gitignore_cluster_repo"
    cat "$gitignore_cluster_repo" "$gitignore_lcm_template" | sponge "$gitignore_cluster_repo"
    git add "${gitignore_cluster_repo}"
  fi
fi

notef "Check if inventory/ has to be removed from version control"
cluster_repository_inventory="$cluster_repository/inventory"
if git ls-files --cached --error-unmatch "$cluster_repository_inventory" &>/dev/null; then
  notef "Removing inventory/ from version control"
  git rm --cached -r --force "$cluster_repository_inventory"
fi
