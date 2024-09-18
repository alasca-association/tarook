#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(cd "$(dirname "$0")/../../actions" && pwd)"

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
vault secrets disable "$cluster_path/calico-pki"
vault secrets disable "$etcd_pki_path"
