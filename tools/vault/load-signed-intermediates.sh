#!/bin/bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

function import_cert {
    local chainfile="$1"
    local pkipath="$2"

    response="$(vault write -format=json "$pkipath/intermediate/set-signed" certificate="@$chainfile")"
    issuer="$(jq -r '.data.imported_issuers[0]' <<<"$response")"
    # If this is a no-op update to an existing issuer, the ID is not included
    # in the response. Hence, we can't init it, but we probably also don't have
    # to (because it has been imported before).
    if [ "$issuer" != 'null' ]; then
        vault write "$pkipath/issuer/$issuer" leaf_not_after_behavior=truncate
        vault write "$pkipath/config/issuers" default="$issuer" >/dev/null
    fi
}

import_cert k8s-cluster.fullchain.pem "$k8s_pki_path"
import_cert k8s-front-proxy.fullchain.pem "$k8s_front_proxy_pki_path"
import_cert k8s-calico.fullchain.pem "$calico_pki_path"
import_cert k8s-etcd.fullchain.pem "$etcd_pki_path"
