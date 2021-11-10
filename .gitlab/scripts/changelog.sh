#!/usr/bin/env bash

set -euo pipefail

PUBLIC_PROJECT_ID='29738620'     # yaook/k8s

function generate_changelog() {
    curl --header "PRIVATE-TOKEN: $TOKEN" \
        --data "version=$VERSION&branch=$BRANCH&from=$FROM_SHA" \
        --fail \
        --silent \
        --show-error \
        "https://gitlab.com/api/v4/projects/$PUBLIC_PROJECT_ID/repository/changelog"
}

# commit hash may be an env var outside of the CI
if [ -z "$FROM_SHA" ]; then
    # for direct commits to devel/stable
    if [ "$CI_COMMIT_BEFORE_SHA" != "0000000000000000000000000000000000000000" ]; then
        export FROM_SHA=$CI_COMMIT_BEFORE_SHA
    # for merge requests
    elif [ -n "$CI_MERGE_REQUEST_TARGET_BRANCH_SHA" ]; then
        export FROM_SHA=$CI_MERGE_REQUEST_TARGET_BRANCH_SHA
    fi
fi

if [ -n "$FROM_SHA" ]; then
    echo "Using $FROM_SHA as starting commit"
else
    echo 'Could not determine starting commit'
    exit 1
fi

echo 'Updating changelog on the remote branch...'

if generate_changelog
then
    if [ "${CI:-false}" == "false" ]; then
        echo 'Updating local branch...'
        git pull origin "$BRANCH"
    fi
    echo 'The changelog has been updated'
else
    echo "Failed to generate the changelog for version $VERSION on branch $BRANCH"
    exit 1
fi
