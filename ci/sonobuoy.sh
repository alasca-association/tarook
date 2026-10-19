#!/usr/bin/env bash
set -euo pipefail

RESULT_DIR="./diagnostics/sonobuoy/"

function log() {
  echo "$(date -u +%T): $*"
}

# Start sonobuoy
sonobuoy run --mode=certified-conformance
sleep 60

# Get state
while true; do
  if out=$(sonobuoy status --json 2>/dev/null); then
    state=$(echo "$out" | jq -r .status)
    log "$state"

    if [ "$state" = "complete" ]; then break; fi
    if [ "$state" = "failed" ]; then log "$out"; exit 1; fi
  else
    log "status check failed, retrying in 60s"
  fi
  sleep 60
done

# Retrieve results
mkdir -p "$RESULT_DIR"
max_retries=5
for i in $(seq "$max_retries"); do
  sonobuoy retrieve "$RESULT_DIR" && break
  if [ "$i" -eq "$max_retries" ]; then log "Could not retrieve results" >&2; exit 1; fi
  sleep 30
done

# Fail if any plugin did not succeed
if ! echo "$out" | jq -e '[.plugins[]."result-status"] | all(. == "passed")' >/dev/null; then
  log "Sonobuoy failed. Please have a look at the jobs artifacts for details." 1>&2
  exit 1
fi
