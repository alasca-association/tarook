#!/usr/bin/env bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

import_cert k8s-cluster.fullchain.pem "$k8s_pki_path"
import_cert k8s-front-proxy.fullchain.pem "$k8s_front_proxy_pki_path"
import_cert k8s-calico.fullchain.pem "$calico_pki_path"
import_cert k8s-etcd.fullchain.pem "$etcd_pki_path"
