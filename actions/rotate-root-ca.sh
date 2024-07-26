#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

helpf() {
  printf "Usage: %s [-n][-c]\n\n" "$0" 1>&2;
  printf "Either [-n] OR [-c] must be specified.\n";
  printf "[-n] Start CA rotation by appending additional issuer 'next'.\n";
  printf "[-c] Complete CA rotation and apply only the default issuer.\n\n";
  exit 2
}

while getopts "nc" flag
do
    case "${flag}" in
        n)
            next_issuer=true
            ;;
        c)
            complete_rotation=true
            ;;
        *)
            echo "Unknown flag passed: '${flag}'" >&2
            helpf
            ;;
    esac
done
shift $(( OPTIND - 1 ))

if [ "$#" != 0 ]; then
  helpf
fi

if [ -z "${next_issuer:-}" ] && [ -z "${complete_rotation:-}" ]; then
  helpf
fi

if [ -n "${next_issuer:-}" ] && [ -n "${complete_rotation:-}" ]; then
  helpf
fi

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"
load_conf_vars

check_venv

check_conf_sanity

require_ansible_disruption

require_vault_token

install_prerequisites

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

# Get a new kubeconfig
run "$actions_dir/k8s-login.sh"

pushd "$ansible_k8s_core_dir"
ansible_playbook -i "$ansible_inventory_host_file" \
  -e "append_next_issuer=${next_issuer:-false}" \
  -e "complete_rotation=${complete_rotation:-false}" \
  rotate-root-ca.yaml "$@"
popd

pushd "$ansible_k8s_supplements_dir"
# Include k8s-core roles
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles:$ansible_k8s_supplements_dir/roles" \
  ansible_playbook -i "$ansible_inventory_host_file" \
  -e "ansible_k8s_core_dir=$ansible_k8s_core_dir" \
  -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
  rotate-root-ca.yaml "$@"
popd

# Get a new kubeconfig
run "$actions_dir/k8s-login.sh"
