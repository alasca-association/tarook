#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")/../../actions"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"


out="$(nix build --print-out-paths --no-link .#docsRST)"
rsync -rL --delete --chmod 664 "$out/" docs/user/reference/options

if [[ -n "${CI_COMMIT_BRANCH:-""}" ]]; then
    git remote set-url origin "https://gitlab-ci-token:${PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
    git fetch origin
    git checkout "${CI_COMMIT_BRANCH}"
    git status
    CHANGES=$(git diff "origin/${CI_COMMIT_BRANCH}" --name-only -- ./docs/user/reference/options | wc -l)
elif [[ -n "${CI_MERGE_REQUEST_IID:-""}" ]]; then
    git remote set-url origin "https://gitlab-ci-token:${PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_MERGE_REQUEST_SOURCE_PROJECT_PATH}.git"
    git fetch origin
    git checkout "origin/${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
    git status
    CHANGES=$(git diff "origin/${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" --name-only -- ./docs/user/reference/options | wc -l)
else
    echo "Automatically rendering docs is only available for MRs and on predefined branches. This pipeline runs for neither of them."
    exit 1
fi

if [ "${CHANGES}" -gt 0 ]; then
    pre-commit install
    echo "committing"
    git add ./docs/user/reference/options
    pre-commit run
    git add ./docs/user/reference/options
    git commit -m "Update rendered docs" -m "job url: ${CI_JOB_URL}"
    if [[ -n "${CI_COMMIT_BRANCH}" ]]; then
        git push
        exit 0
    elif [[ -n "${CI_MERGE_REQUEST_IID}" ]]; then
        git push origin HEAD:"${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
        exit 0
    fi
else
    echo "Rendered docs are up-to-date. Nothing to commit."
fi
