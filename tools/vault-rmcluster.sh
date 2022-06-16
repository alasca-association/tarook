#!/bin/bash
set -euo pipefail
common_path_prefix="${YAOOK_K8S_VAULT_PATH_PREFIX:-yaook}"
cluster="$1"
cluster_path="$common_path_prefix/$cluster"

ssh_ca_path="$cluster_path/ssh-ca"
k8s_pki_path="$cluster_path/k8s-pki"
k8s_front_proxy_pki_path="$cluster_path/k8s-front-proxy-pki"
calico_pki_path="$cluster_path/calico-pki"
etcd_pki_path="$cluster_path/etcd-pki"

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
