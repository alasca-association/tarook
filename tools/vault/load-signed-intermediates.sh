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
"$actions_dir/update-inventory.sh" vault

load_vars

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
