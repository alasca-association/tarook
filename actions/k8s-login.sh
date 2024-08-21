#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"
load_conf_vars

check_conf_sanity

require_vault_token

set_kubeconfig

while getopts s flag
do
    case "${flag}" in
        s)
            super_admin=true
            ;;
        *)
            echo "Unknown flag passed: '${flag}'" >&2
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))
[[ "${0}" == "--" ]] && shift

arg_num=0
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

check_vault_token_policy

pushd "$ansible_k8s_core_dir"
# Include k8s-core roles
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles" \
  ansible_playbook -i "$ansible_inventory_host_file" \
  -e "super_admin=${super_admin:-false}" \
  -e "direct_generation=true" \
  k8s-login.yaml "$@"
popd
