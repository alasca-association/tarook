#!/usr/bin/env bash
set -euo pipefail
cluster="$1"
action="${2:-foo}"
# shellcheck source=tools/vault/lib.sh
# . "$(dirname "$0")/lib.sh"
. managed-k8s/tools/vault/lib.sh

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
    init_k8s_calico_pki_roles "$calico_pki_path" "$pki_ttl"
    echo "NOTE: CSRs have been written to k8s-{cluster,etcd,front-proxy,calico}.csr."
    ;;
    "load-signed-intermediates")
    import_cert k8s-cluster.fullchain.pem "$k8s_pki_path" "next"
    import_cert k8s-front-proxy.fullchain.pem "$k8s_front_proxy_pki_path" "next"
    import_cert k8s-calico.fullchain.pem "$calico_pki_path" "next"
    import_cert k8s-etcd.fullchain.pem "$etcd_pki_path" "next"
    ;;
    "apply")
    rotate_pki_issuer "$k8s_pki_path"
    rotate_pki_issuer "$etcd_pki_path"
    rotate_pki_issuer "$k8s_front_proxy_pki_path"
    rotate_pki_issuer "$calico_pki_path"
    # ToDo: Invalidate/delete previous issuer
    ;;
    *)
    echo "Usage $0 <clustername> [prepare|apply|load-signed-intermediates]"
    ;;
esac