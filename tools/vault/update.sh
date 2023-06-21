#!/bin/bash
set -euo pipefail

function usage() {
    echo "usage: $0 CLUSTERNAME" >&2
    echo >&2
    echo "Arguments:" >&2
    echo "    CLUSTERNAME" >&2
    echo "        The name of the cluster, inside Vault, to use." >&2
    echo >&2
}

if [ "$#" -ne 1 ]; then
    usage
    exit 2
fi

cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"
scriptdir="$(dirname "$0")"

pki_ttl=8784h

echo "Initializing PKI engines ..."

init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"
init_k8s_calico_pki_roles "$calico_pki_path" "$pki_ttl"

