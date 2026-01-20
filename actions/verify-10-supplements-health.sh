#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

load_conf_vars

check_conf_sanity

while getopts s flag
do
    case "${flag}" in
        s)
            k8s_skip_upgrade_checks=true
            ;;
        *)
            echo "Unknown flag passed: '${flag}'" >&2
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))

check_venv

set_kubeconfig

pushd "$ansible_k8s_supplements_dir"
# Include k8s-core roles
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles:$ansible_k8s_supplements_dir/roles" \
  ansible_playbook -i "$ansible_inventory_host_file" \
  -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
  -e "ansible_python_interpreter=${ANSIBLE_PYTHON_INTERPRETER:-"$(command -v python)"}" \
  verify-cluster-health.yaml "$@"
popd
