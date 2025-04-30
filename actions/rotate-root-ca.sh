#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

helpf() {
  printf "Usage: %s [-n <vault_clustername>][-c]\n\n" "$0" 1>&2;
  printf "Either [-n] OR [-c] must be specified.\n";
  printf "[-n <vault_clustername>] Start CA rotation by appending issuer 'default' of the given clustername.\n";
  printf "[-c] Complete CA rotation and apply only the new configured issuer.\n\n";
  exit 2
}

while getopts "n:c" flag
do
    case "${flag}" in
        n)
            next_issuer=true
            next_vault_clustername="${OPTARG}"
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

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

if "${next_issuer:-false}"; then
  confirm_vault_clustername "$next_vault_clustername"
fi

load_conf_vars

check_venv

check_conf_sanity

require_ansible_disruption

require_vault_token

install_prerequisites


# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

set_kubeconfig

# Get a new kubeconfig
# If we are completing a CA rotation, renewal must only happen in the end
if [ "${complete_rotation:-false}" == "false" ]; then
  run "$actions_dir/k8s-login.sh"
fi

pushd "$ansible_k8s_core_dir"
ansible_playbook -i "$ansible_inventory_host_file" \
  -e "append_next_issuer=${next_issuer:-false}" \
  -e "next_vault_cluster_name=${next_vault_clustername:-}" \
  -e "complete_rotation=${complete_rotation:-false}" \
  rotate-root-ca.yaml "$@"
popd

pushd "$ansible_k8s_supplements_dir"
# Include k8s-core roles
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles:$ansible_k8s_supplements_dir/roles" \
  ansible_playbook -i "$ansible_inventory_host_file" \
  -e "append_next_issuer=${next_issuer:-false}" \
  -e "next_vault_cluster_name=${next_vault_clustername:-}" \
  -e "ansible_k8s_core_dir=$ansible_k8s_core_dir" \
  -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
  rotate-root-ca.yaml "$@"
popd

# Get a new kubeconfig
AFLAGS="-e append_next_issuer=${next_issuer:-false} -e next_vault_cluster_name=${next_vault_clustername:-}" "$actions_dir/k8s-login.sh"
