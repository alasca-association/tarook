#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")/../../actions"

# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

arg_num=0
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

cluster="$(get_clustername)"
# reload the lib to update the vars after initializing the clustername
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

_k8s_cluster_cert=( "k8s-cluster.fullchain.pem" "$k8s_pki_path" )
_k8s_front_proxy_cert=( "k8s-front-proxy.fullchain.pem" "$k8s_front_proxy_pki_path" )
_k8s_etcd_cert=( "k8s-etcd.fullchain.pem" "$etcd_pki_path" )

for _cert in _k8s_cluster_cert _k8s_front_proxy_cert _k8s_etcd_cert; do
    # Rotate if there is at least one pre-existing issuer
    # NOTE: 'issuer/default' always points to an issuer unless there are none
    if (vault read ${_cert[1]}/issuer/default &>/dev/null); then
        import_cert "${_cert[0]}" "${_cert[1]}" "next"
        rotate_pki_issuer "${_cert[1]}"
    else
        import_cert "${_cert[0]}" "${_cert[1]}" "current"
    fi
done
