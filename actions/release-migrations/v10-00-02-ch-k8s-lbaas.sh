#!/usr/bin/env bash

# NOTE: This migration must be run before port security is enabled by Terraform

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Let ch-k8s-lbaas version >= 0.8.0 be enforced by Nix
run "$actions_dir/update-inventory.sh" ansible

notef "Triggering install-ch-k8s-lbaas.yaml playbook to update ch-k8s-lbaas."
run "$actions_dir/apply-k8s-supplements.sh" install-ch-k8s-lbaas.yaml
