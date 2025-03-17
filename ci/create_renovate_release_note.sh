#!/usr/bin/env bash
set -euo pipefail

# This script is used to create an empty release note
# of the category "chore".
# This script is triggered as "postUpgradeTasks"
# by the renovate bot.

DATE_STRING="$(date --iso-8601=seconds -u)"
RELEASENOTE_PATH="docs/_releasenotes"

DATASOURCE=$1
DEP_NAME=$2
SOURCE_URL=$3
CURRENT_VERSION=$4
NEW_VERSION=$5

if [[ $DATASOURCE == 'helm' ]]; then
  CATEGORY="feature"
else
  CATEGORY="chore"
fi

# Prevent overwriting any existing news fragment
#  by selecting a free counter number
while [ -f "$RELEASENOTE_PATH/+.$CATEGORY.${counter:=1}.$DATE_STRING" ]; do
  ((counter++))
done
news_fragment_file="$RELEASENOTE_PATH/+.$CATEGORY.${counter}.$DATE_STRING"

if [[ $CATEGORY == 'feature' && $DATASOURCE == 'helm' ]]; then
  echo "Updated default version of helm chart $DEP_NAME of $SOURCE_URL from $CURRENT_VERSION to $NEW_VERSION" > "${news_fragment_file}"
else
  touch "${news_fragment_file}"
fi
