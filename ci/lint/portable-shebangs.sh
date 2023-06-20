#!/usr/bin/env bash

fix() {
  filename="$1"
  orig="$2"
  new="$3"
  echo "Fixing shebang of $filename"
  sed -i 's|'"$orig"'|'"$new"'|g' "$filename"
  error=true
}

error=false
while [[ $# -gt 0 ]]; do
  firstline="$(head -n1 "$1")"
  case "$firstline" in
    '#!/bin/sh'*)
      true
      ;;
    '#!/usr/bin/env'*)
      true
      ;;
    '#!/bin/bash')
      fix "$1" '^#!/bin/bash$' '#!/usr/bin/env bash'
      ;;
    '#!/usr/bin/python')
      fix "$1" '^#!/usr/bin/python$' '#!/usr/bin/env python'
      ;;
    '#!/usr/bin/python3')
      fix "$1" '^#!/usr/bin/python3$' '#!/usr/bin/env python3'
      ;;
    *)
      echo "${1}: Shebang '$firstline' is not portable and can't be auto-fixed."
      echo "Use '#!/bin/sh' or '#!/usr/bin/env interpreter' instead."
      error=true
      ;;
  esac
  shift
done
if [ "$error" = true ]; then
  exit 1
fi
