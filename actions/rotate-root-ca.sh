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

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

require_disruption

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

export KUBECONFIG="$cluster_repository/inventory/.etc/admin.conf"
cd "$ansible_k8s_base_playbook"
ansible-galaxy install -r "$ansible_directory/requirements.yaml"

ansible_playbook -i "$ansible_inventoryfile_03" \
  -e "append_next_issuer=${next_issuer:-false}" \
  -e "complete_rotation=${complete_rotation:-false}" \
  rotate_root_ca.yaml "$@"

cd "$ansible_k8s_sl_playbook"
ansible_playbook -i "inventory/default.yaml" \
  -e "ksl_vars_directory=$ansible_k8s_sl_vars_base" \
  rotate_root_ca.yaml
