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
    if [ $i -gt 0 ]; then
        # emit a clearly visible marker so that it's easily found when scrolling
        # we emit it here (and not at the bottom) to not emit it on the last attempt
        # 1;31m is bright red
        printf '\x1b[1;31mRETRY RETRY RETRY RETRY RETRY RETRY RETRY RETRY RETRY\x1b[0m\n'
        printf '\x1b[1;31mRETRY RETRY RETRY RETRY RETRY RETRY RETRY RETRY RETRY\x1b[0m\n'
        printf '\x1b[1;31mRETRY RETRY RETRY RETRY RETRY RETRY RETRY RETRY RETRY\x1b[0m\n'
    fi
    if timeout "$TIMEOUT" "$COMMAND"; then
        exit 0;
    fi
    i=$((i + 1));
    echo "Command failed on $i attempt :( I'll retry until $ATTEMPTS attempts are made";
done

if [ $i -gt 0 ]; then
    # 1;33m is bright yellow
    printf '\x1b[1;33m***********************************************\x1b[0m\n'
    printf '\x1b[1;33m*                                             *\x1b[0m\n'
    printf '\x1b[1;33m* The command was retried %d times!           *\x1b[0m\n' "$i"
    printf '\x1b[1;33m* The error you see above may not be the real *\x1b[0m\n'
    printf '\x1b[1;33m* error and you'"'"'ll have to scroll up a lot.   *\x1b[0m\n'
    printf '\x1b[1;33m*                                             *\x1b[0m\n'
    printf '\x1b[1;33m***********************************************\x1b[0m\n'
fi

exit $FAILED
