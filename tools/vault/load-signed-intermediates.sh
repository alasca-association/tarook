#!/bin/bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

vault write "$k8s_pki_path/intermediate/set-signed" certificate=@k8s-cluster.crt
vault write "$etcd_pki_path/intermediate/set-signed" certificate=@k8s-etcd.crt
vault write "$k8s_front_proxy_pki_path/intermediate/set-signed" certificate=@k8s-front-proxy.crt
vault write "$calico_pki_path/intermediate/set-signed" certificate=@k8s-calico.crt
