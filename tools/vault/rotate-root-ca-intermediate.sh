#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")/../../actions"

# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

usage() {
    echo "Usage: $0 [prepare|apply|load-signed-intermediates]"
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
check_clustername "$cluster"
# reload the lib to update the vars after initializing the clustername
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

action="${1:-foo}"

# maximum time for certificates to live: 1 calendar year (leap year compatible)
pki_ttl=8784h
# 1.5yrs
pki_intermediate_ttl=13176h

case "$action" in
    "prepare")
    mkcsrs "$pki_intermediate_ttl"
    init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
    init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
    init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"
    echo "NOTE: CSRs have been written to k8s-{cluster,etcd,front-proxy}.csr."
    ;;
    "load-signed-intermediates")
    import_cert k8s-cluster.fullchain.pem "$k8s_pki_path" "next"
    import_cert k8s-front-proxy.fullchain.pem "$k8s_front_proxy_pki_path" "next"
    import_cert k8s-etcd.fullchain.pem "$etcd_pki_path" "next"
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
