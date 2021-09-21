#!/bin/bash
set -uo pipefail
outfile="$1"
shift
jsonnet "$@" | sponge "$outfile"
status="$?"
if [ "x$status" != "x0" ]; then
    rm -f "$outfile"
fi
set -e
python3 -c 'import sys, json; json.dump(sorted(filter(None, map(str.strip, open(sys.argv[1])))), sys.stdout)' "$outfile" | sponge "$outfile.json"
status="$?"
if [ "x$status" != "x0" ]; then
    rm -f "$outfile" "$outfile.json"
fi
exit $status
