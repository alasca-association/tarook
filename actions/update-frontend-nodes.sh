#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

check_venv

require_ansible_disruption

# Ensure that the latest config is deployed to the inventory
python3 "$actions_dir/update_inventory.py"

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

require_double_sigint

install_prerequisites

# Bring the wireguard interface up if configured so
"$actions_dir/wg-up.sh"

# Trigger whole LCM
pushd "$ansible_k8s_core_dir"
# Include k8s-core roles
ansible_playbook -i "$ansible_inventory_host_file" \
  -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
  update-frontend-nodes.yaml "$@"
popd
