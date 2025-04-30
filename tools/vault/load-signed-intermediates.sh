#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

arg_num=1
if [ "$#" -gt "$arg_num" ]; then
    echo "ERROR: Expecting at most $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

if [ "${1:+x}" == "x" ]; then
    # clustername given as argument
    cluster="$1"
    check_clustername "$cluster" cmdline
else
    # use configured clustername
    cluster="$(get_clustername)"
    check_clustername "$cluster" config
fi

# reload the lib to update the vars after initializing the clustername
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

function import_signed_intermediate() {
    local cert_file="$1"
    local cert_path="$2"

    # Rotate if there is at least one pre-existing issuer
    # NOTE: 'issuer/default' always points to an issuer unless there are none
    if (vault read "${cert_path}/issuer/default" &>/dev/null); then
        import_cert "${cert_file}" "${cert_path}" "next"
        rotate_pki_issuer "${cert_path}"
    else
        import_cert "${cert_file}" "${cert_path}" "current"
    fi
}

import_signed_intermediate "k8s-cluster.fullchain.pem" "$k8s_pki_path"
import_signed_intermediate "k8s-front-proxy.fullchain.pem" "$k8s_front_proxy_pki_path"
import_signed_intermediate "k8s-etcd.fullchain.pem" "$etcd_pki_path"
