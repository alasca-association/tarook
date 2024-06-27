#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")/../../actions"


# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

usage() {
    echo "Usage $0 [prepare|apply]"
}

arg_num=1
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    usage
    exit 2
fi

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

cluster="$(get_clustername)"
# reload the lib to update the vars after initializing the clustername
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

action="${1:-foo}"

# maximum time for certificates to live: 1 calendar year (leap year compatible)
pki_ttl=8784h
# 5yrs
pki_root_ttl=43830h

case "$action" in
    "prepare")
    # Require permission when Kubernetes cluster CA backup is going to be destroyed
    # by generate_ca_issuer()
    require_k8s_cluster_ca_backup_destruction

    generate_ca_issuer "$pki_root_ttl" "next"
    init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
    init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
    init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"
    ;;
    "apply")
    rotate_pki_issuer "$k8s_pki_path"
    rotate_pki_issuer "$etcd_pki_path"
    rotate_pki_issuer "$k8s_front_proxy_pki_path"
    # ToDo: Invalidate/delete previous issuer
    ;;
    *)
    usage
    ;;
esac
