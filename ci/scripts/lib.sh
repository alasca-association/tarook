# shellcheck shell=bash disable=SC2154,SC2034

actions_dir="$(dirname "$0")/../../actions"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

function diff_and_commit() {
    run git remote set-url origin "${REMOTE_URL}"
    run git fetch origin
    run git checkout "${REMOTE_BRANCH}"
    run git add "${DIFF_PATH}"
    run git status
    CHANGES=$(git diff "${REMOTE_BRANCH}" --staged --name-only -- "${DIFF_PATH}" | wc -l)
    if [ "${CHANGES}" -gt 0 ]; then
        run git commit -m "${COMMIT_MSG}" -m "job url: ${CI_JOB_URL}"
    else
        echo "Files are up-to-date. Nothing to commit."
    fi
}

function push_if_changed() {
    if [[ -n "${CI_COMMIT_BRANCH:-""}" ]]; then
        REMOTE_URL="https://gitlab-ci-token:${PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
        REMOTE_BRANCH="${CI_COMMIT_BRANCH}"
        diff_and_commit
        run git push
        exit "$CHANGES"
    elif [[ -n "${CI_MERGE_REQUEST_IID:-""}" ]]; then
        REMOTE_URL="https://gitlab-ci-token:${PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_MERGE_REQUEST_SOURCE_PROJECT_PATH}.git"
        REMOTE_BRANCH="origin/${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
        diff_and_commit
        run git push origin HEAD:"${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
        exit "$CHANGES"
    else
        echo "Housekeeping is only available for MRs and on predefined branches. This pipeline runs for neither of them."
        exit 1
    fi
}
