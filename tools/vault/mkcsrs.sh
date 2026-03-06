#!/usr/bin/env bash
#
# Script which can be used to create new CSRs.

set -euo pipefail
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

arg_num=0
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

load_vars

pki_intermediate_ttl=13176h  # 1.5 years
mkcsrs "$pki_intermediate_ttl"

echo "NOTE: CSRs have been written to k8s-{cluster,etcd,front-proxy}.csr."
