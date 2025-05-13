#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if [[ -e "$release_migration_lock" ]]; then
  notef "Detected ongoing release migration. Re-trying..."
elif [[ "$(git status --short --porcelain | grep --count --invert-match --extended-regexp '^[ ].*[ ]+(managed-k8s|submodules|.gitmodules)')" -ne 0 ]]; then
  errorf "Cluster repository not clean. Refusing to run release migration"
  exit 1
fi

mkdir -p "$(dirname "$release_migration_lock")"
cat <<EOF > "$release_migration_lock"
The presence of this file means that cluster release migration has not been completed successfully.
Please re-run \`$0\` to finish release migration.
EOF

export IGNORE_MIGRATION_LOCK=true

run git add .gitmodules managed-k8s

find "${actions_dir}/release-migrations" -type f -executable | sort | while read -r script; do
  bash -euo pipefail "$script" || exit 1
done

if (git ls-files --error-unmatch "$release_migration_lock" &> /dev/null); then
  run git rm -f "$release_migration_lock"
else
  rm "$release_migration_lock"
fi

run git commit --author "Tarook v${version_major_minor} release release migration script <>" --message "Migrate cluster repository to v${version_major_minor}"

notef "Migration successful. You may continue to use your cluster now."
