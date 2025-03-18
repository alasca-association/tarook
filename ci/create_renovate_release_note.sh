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

if [[ $DATASOURCE == 'helm' ]]; then
  if [[ $IS_MAJOR == 'true' ]]; then
    CATEGORY="BREAKING"
  else
    CATEGORY="change"
  fi
else
  CATEGORY="chore"
fi

RELEASENOTE_FILE="$RELEASENOTES_BASE_PATH/x.$CATEGORY.$DEP_NAME-updated-to-$NEW_VERSION"

if [ -f "$RELEASENOTE_FILE" ]; then
  >&2 echo "File $RELEASENOTE_FILE already exists. Something is odd."
  exit 2
fi

if [[ $DATASOURCE == 'helm' ]]; then
  echo "Updated default version of helm chart $DEP_NAME of $SOURCE_URL from $CURRENT_VERSION to $NEW_VERSION" > "$RELEASENOTE_FILE"
else
  touch "$RELEASENOTE_FILE"
fi
