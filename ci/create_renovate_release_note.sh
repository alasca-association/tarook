#!/usr/bin/env bash
set -euo pipefail

# This script is used to create an appropriate release note
# for changes requested by the renovate bot.
# It is triggered as a "postUpgradeTask"
# https://docs.renovatebot.com/configuration-options/#postupgradetasks

RELEASENOTES_BASE_PATH="docs/_releasenotes"

DATASOURCE=$1
DEP_NAME=$2
SOURCE_URL=$3
CURRENT_VERSION=$4
NEW_VERSION=$5
IS_MAJOR=$6

CATEGORY="dependency"
if [[ $DATASOURCE == 'helm' && $IS_MAJOR == 'true' ]]; then
  CATEGORY="BREAKING"
fi

RELEASENOTE_FILE="$RELEASENOTES_BASE_PATH/x.$CATEGORY.$DEP_NAME-updated-to-$NEW_VERSION"

if [ -f "$RELEASENOTE_FILE" ]; then
  >&2 echo "File $RELEASENOTE_FILE already exists. Something is odd."
  exit 2
fi

if [[ $DATASOURCE == 'helm' ]]; then
  if [[ -z $SOURCE_URL ]]; then
    echo "Updated default version of helm chart $DEP_NAME from $CURRENT_VERSION to $NEW_VERSION" > "$RELEASENOTE_FILE"
  else
    echo "Updated default version of helm chart $DEP_NAME of $SOURCE_URL from $CURRENT_VERSION to $NEW_VERSION" > "$RELEASENOTE_FILE"
  fi
elif [[ $SOURCE_URL == 'https://github.com/containerd/containerd' ]]; then
  echo "The default version of containerd has been bumped from $CURRENT_VERSION to $NEW_VERSION." > "$RELEASENOTE_FILE"
elif [[ $SOURCE_URL == 'https://github.com/kubernetes/kubernetes' ]]; then
  echo "The default Kubernetes version has been bumped from $CURRENT_VERSION to $NEW_VERSION." > "$RELEASENOTE_FILE"
else
  touch "$RELEASENOTE_FILE"
fi
