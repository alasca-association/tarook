#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")/../../actions"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

arg_num=0
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

cluster="$(get_clustername)"
check_clustername "$cluster"
# reload the lib to update the vars after initializing the clustername
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

import_cert k8s-cluster.fullchain.pem "$k8s_pki_path"
import_cert k8s-front-proxy.fullchain.pem "$k8s_front_proxy_pki_path"
import_cert k8s-etcd.fullchain.pem "$etcd_pki_path"
