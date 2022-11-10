#!/usr/bin/env bash
set -euo pipefail

if [ "$#" != 1 ] && [ "$#" != 2 ]; then
  printf 'usage: %s URL [INTERVAL]\n\n' "$0" >&2
  printf 'Periodically poll URL over HTTP.\n\n' >&2
  printf 'positional arguments:\n' >&2
  printf '  URL       the URL to poll (via curl(1))\n' >&2
  printf '  INTERVAL  time to sleep(1) between polls (default: 0.5)\n' >&2
  printf '\n\n'
  printf 'This script polls the target URL periodically and logs whether\n' >&2
  printf 'each poll was successful or not, including timestamps.\n\n' >&2
  printf 'This is useful to monitor availability of services inside k8s\n' >&2
  printf 'cluster while testing critical operations.\n' >&2
  exit 2
fi

dest="$1"
interval="${2:-0.5}"
okcount=0
failcount=0

function print_stats() {
  echo
  echo "PASSED: $okcount"
  echo "FAILED: $failcount"
  echo
}

trap print_stats EXIT

while true; do
  date --iso-8601=seconds | tr -d '\n'
  printf ' '
  if curl -sS -o last "$dest"; then 
    okcount="$((okcount+1))"
    echo 'OK'
  else
    failcount="$((failcount+1))"
  fi
  sleep "$interval"
done
