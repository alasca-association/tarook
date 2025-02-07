#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

if [[ -e "$migration_lock" ]]; then
  notef "Detected ongoing migration. Re-trying..."
elif [[ "$(git status --short --porcelain | grep --count --invert-match --extended-regexp '^[ ].*[ ]+(managed-k8s|submodules|.gitmodules)')" -ne 0 ]]; then
  errorf "Cluster repository not clean. Refusing to run migration"
  exit 1
fi

mkdir -p "$(dirname "$migration_lock")"
cat <<EOF > "$migration_lock"
The presence of this file means that cluster migration has not been completed successfully.
Please re-run migrate-cluster-repo.sh to finish migration.
EOF

export IGNORE_MIGRATION_LOCK=true

run git add .gitmodules managed-k8s

find "${actions_dir}/migrations" -type f -executable | sort | while read -r script; do
  bash -euo pipefail "$script" || exit 1
done

if (git ls-files --error-unmatch "$migration_lock" &> /dev/null); then
  run git rm -f "$migration_lock"
else
  rm "$migration_lock"
fi

run git commit --author "YAOOK/K8s v${version_major_minor} release migration script <>" --message "Migrate cluster repository to v${version_major_minor}"

notef "Migration successful. You may continue to use your cluster now."
