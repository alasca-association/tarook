#!/bin/bash

SCRIPTPATH="$( dirname "$(realpath "$0")")"

for f in "${SCRIPTPATH}"/scripts/*.sh; do
    $f "$@"
done
