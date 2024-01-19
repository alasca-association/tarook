#!/usr/bin/env bash
set -euo pipefail

# This script is used to create an empty release note
# of the category "chore".
# This script is triggered as "postUpgradeTasks"
# by the renovate bot.

DATE_STRING="$(date --iso-8601=seconds -u)"
RELEASENOTE_PATH="docs/_releasenotes"

while [ -f "$RELEASENOTE_PATH/+.chore.$DATE_STRING" ]; do
  DATE_STRING="$(date --iso-8601=seconds -u)"
done

touch "$RELEASENOTE_PATH/+.chore.$DATE_STRING"
