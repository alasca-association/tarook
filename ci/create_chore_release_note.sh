#!/usr/bin/env bash
set -euo pipefail

# This script is used to create an empty release note
# of the category "chore".
# This script is triggered as "postUpgradeTasks"
# by the renovate bot.

RANDOM_STRING="cahiechooPaew7Yi"
RELEASENOTE_PATH="docs/_releasenotes"

while [ -f "$RELEASENOTE_PATH/+.chore.$RANDOM_STRING" ]; do
  RANDOM_STRING="$(pwgen 16 1)"
  echo "$RANDOM_STRING"
done

touch "$RELEASENOTE_PATH/+.chore.$(pwgen 16 1)"
