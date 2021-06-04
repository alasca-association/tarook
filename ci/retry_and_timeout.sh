#!/bin/bash

# This module is intended to be used by the CI

set -euo pipefail

COMMAND=$1
ATTEMPTS=$2
TIMEOUT=$3

FAILED=1

i=0;


while [ $i -lt "$ATTEMPTS" ]
do
    if timeout "$TIMEOUT" "$COMMAND"; then
        exit 0;
    fi
    i=$((i + 1));
    echo "Command failed on $i attempt :( I'll retry until $ATTEMPTS attempts are made";
done

exit $FAILED
