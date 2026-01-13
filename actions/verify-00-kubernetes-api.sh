#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

set_kubeconfig

# Do some rudimentary checks to verify the Kubernetes API is reachable
retries=0
until [[ "$(kubectl get --raw='/readyz' 2> /dev/null)" == "ok" ]]
do
  if [[ "$retries" -gt 100 ]]; then
    errorf "Kubernetes API is not healthy."
    exit 1
  else
    ((retries+=1))
  fi
  sleep 3
done

retries=0
until kubectl get nodes &> /dev/null
do
  if [[ "$retries" -gt 100 ]]; then
    errorf "Kubernetes API is not healthy."
    exit 1
  else
    ((retries+=1))
  fi
  sleep 3
done
