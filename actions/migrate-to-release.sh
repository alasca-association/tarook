#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

load_conf_vars
check_venv
set_kubeconfig

if [ "${tf_usage:-true}" == 'true' ]; then
  notef "Triggering Terraform"
  run "$actions_dir/apply-terraform.sh"
fi

if [ "$(tomlq --raw-output '."ch-k8s-lbaas".enabled' config/config.toml)" == 'true' ]; then
  if [ "$(tomlq --raw-output '."ch-k8s-lbaas".version' config/config.toml)" != 'null' ]; then
    if [ "$("$actions_dir/helpers/semver2.sh" "$(tomlq --raw-output '."ch-k8s-lbaas".version' config/config.toml)" "0.8.0")" -lt 0 ]; then
      errorf "Your configured ch-k8s-lbaas version is too old."
      errorf "You must configure at least version v0.8.0."
      errorf "It is recommended to not pin ch-k8s-lbaas to a specific version."
      exit 2
    fi
  fi
  notef "Triggering install-ch-k8s-lbaas.yaml playbook to update ch-k8s-lbaas."
  run "$actions_dir/apply-k8s-supplements.sh" install-ch-k8s-lbaas.yaml
fi

notef "Update keepalived configuration."
AFLAGS="--diff -t keepalived" run "$actions_dir/apply-k8s-core.sh" install-frontend-services.yaml
