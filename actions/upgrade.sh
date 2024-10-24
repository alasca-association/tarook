#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"
load_conf_vars

check_conf_sanity

check_venv

require_vault_token

install_prerequisites

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
[[ "${1}" == "--" ]] && shift

if [ "$#" != 1 ]; then
    printf 'usage: %s TARGET_VERSION\n\n' "$0" >&2
    printf 'Positional arguments:\n' >&2
    printf '    TARGET_VERSION  The kubernetes version to upgrade to\n' >&2
    exit 2
fi

target_version="$1"
if ! echo "$target_version" | grep -Pq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    # this explicit check is here to ensure that we don’t do any bad things
    # when composing the command line below.
    errorf 'this does not look like a valid Kubernetes version: %q' "$target_version"
    exit 2
fi
minor_version="$(echo "$target_version" | cut -d'.' -f1-2)"
playbook="k8s-upgrade-to-${minor_version}.yaml"

if [ ! -e "${ansible_k8s_supplements_dir}/${playbook}" ]; then
    errorf 'cannot find an upgrade playbook for target minor version %q' "$minor_version"
    hintf 'I looked for %q' "${ansible_k8s_supplements_dir}/${playbook}"
    exit 2
fi

hintf 'Executing upgrade to version %s (patch level %s)' "$minor_version" "$target_version"

require_ansible_disruption

"$actions_dir/wg-up.sh"

set_kubeconfig

pushd "$ansible_k8s_supplements_dir"
ANSIBLE_ROLES_PATH="$ansible_k8s_core_dir/roles:$ansible_k8s_supplements_dir/roles" \
    ansible_playbook -i "$ansible_inventory_host_file" "$playbook" \
    -e "next_k8s_version=$target_version" \
    -e "next_minor_k8s_version=$minor_version" \
    -e '{"do_upgrade": true}' \
    -e "k8s_skip_upgrade_checks=${k8s_skip_upgrade_checks:-false}" \
    -e "ansible_k8s_core_dir=$ansible_k8s_core_dir"
popd
