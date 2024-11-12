#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")/../../actions"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

function diff_options() {
    url="$1"
    branch="$2"

    run git remote set-url origin "${url}"
    run git fetch origin
    run git checkout "${branch}"
    run git add ./docs/user/reference/options
    run pre-commit run
    run git add ./docs/user/reference/options
    run git status
    CHANGES=$(git diff "${branch}" --staged --name-only -- ./docs/user/reference/options | wc -l)
}

run nix build --no-link .#docsRST
out="$(nix build --print-out-paths --no-link .#docsRST)"
run rsync -rL --delete --chmod 664 "$out/" docs/user/reference/options

if [[ -n "${CI_COMMIT_BRANCH:-""}" ]]; then
    diff_options "https://gitlab-ci-token:${PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" "${CI_COMMIT_BRANCH}"
elif [[ -n "${CI_MERGE_REQUEST_IID:-""}" ]]; then
    diff_options "https://gitlab-ci-token:${PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_MERGE_REQUEST_SOURCE_PROJECT_PATH}.git" "origin/${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
else
    echo "Automatically rendering docs is only available for MRs and on predefined branches. This pipeline runs for neither of them."
    exit 1
fi

if [ "${CHANGES}" -gt 0 ]; then
    run pre-commit install
    run git commit -m "Update rendered docs" -m "job url: ${CI_JOB_URL}"
    if [[ -n "${CI_COMMIT_BRANCH}" ]]; then
        run git push
        exit 0
    elif [[ -n "${CI_MERGE_REQUEST_IID}" ]]; then
        run git push origin HEAD:"${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
        exit 0
    fi
else
    echo "Rendered docs are up-to-date. Nothing to commit."
fi
