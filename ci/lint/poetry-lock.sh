#!/usr/bin/env bash

poetry lock --no-update

if [[ -n "${CI_COMMIT_BRANCH}" ]]; then
    git remote set-url origin "https://gitlab-ci-token:${PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
    git fetch origin
    git checkout "${CI_COMMIT_BRANCH}"
    git status
    CHANGES=$(git diff "origin/${CI_COMMIT_BRANCH}" --name-only -- ./poetry.lock | wc -l)
elif [[ -n "${CI_MERGE_REQUEST_IID}" ]]; then
    git remote set-url origin "https://gitlab-ci-token:${PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_MERGE_REQUEST_SOURCE_PROJECT_PATH}.git"
    git fetch origin
    git checkout "origin/${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
    git status
    CHANGES=$(git diff "origin/${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" --name-only -- ./poetry.lock | wc -l)
else
    echo "Autofix of poetry.lock is only available for MRs and on predefined branches. This pipeline runs for neither of them."
    exit 1
fi

if [ "${CHANGES}" -gt 0 ]; then
    echo "committing"
    git add ./poetry.lock
    git commit -m "auto fixes for poetry.lock" -m "job url: ${CI_JOB_URL}"
    if [[ -n "${CI_COMMIT_BRANCH}" ]]; then
        git push
        exit 0
    elif [[ -n "${CI_MERGE_REQUEST_IID}" ]]; then
        git push origin HEAD:"${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}"
        exit 0
    fi
else
    echo "Poetry.lock is up-to-date. Nothing to commit."
fi
