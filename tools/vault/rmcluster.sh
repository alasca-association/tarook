#!/bin/bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

echo 'This will REMOVE all data stored in vault related to the cluster'
echo
echo "    ${cluster}"
echo
echo
read -r -p "ARE YOU SURE? (type capital 'yes')" response
case "$response" in
    YES)
        ;;
    *)
        echo 'User consent not given, bailing out.' >&2
        exit 2
        ;;
esac

vault secrets disable "$cluster_path/kv"
vault secrets disable "$ssh_ca_path"
vault secrets disable "$k8s_pki_path"
vault secrets disable "$k8s_front_proxy_pki_path"
vault secrets disable "$calico_pki_path"
vault secrets disable "$etcd_pki_path"
