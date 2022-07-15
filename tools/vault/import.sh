#!/bin/bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

inventory_etc=inventory/.etc
flag_file="$inventory_etc/migrated-to-vault"

if [ ! -d 'inventory/.etc' ]; then
    echo "$0: inventory/.etc does not exist. are you running this from the right place?" >&2
    exit 1
fi

if [ -e "$flag_file" ]; then
    echo "$0: presence of $flag_file indicates that migration has already happened." >&2
    echo "$0: refusing to continue." >&2
    exit 2
fi

if vault kv get "$cluster_path/kv/k8s/service-account-key" >/dev/null 2>/dev/null; then
    echo "$0: service account key already present in vault. does this cluster alreay exist?" >&2
    echo "$0: refusing to continue." >&2
    exit 2
fi

echo "Importing CA bundles ..."

cat "$inventory_etc/ca.crt" "$inventory_etc/ca.key" | vault write "$k8s_pki_path/config/ca" pem_bundle=-
cat "$inventory_etc/front-proxy-ca.crt" "$inventory_etc/front-proxy-ca.key" | vault write "$k8s_front_proxy_pki_path/config/ca" pem_bundle=-
cat "$inventory_etc/calico/typhaca.crt" "$inventory_etc/calico/typhaca.key" | vault write "$calico_pki_path/config/ca" pem_bundle=-
cat "$inventory_etc/etcd/ca.crt" "$inventory_etc/etcd/ca.key" | vault write "$etcd_pki_path/config/ca" pem_bundle=-

echo "Importing other secrets ..."

PASSWORD_STORE_DIR="$inventory_etc/passwordstore" pass show wg_gw_key | head -n1 | tr -d '\n' | vault kv put "$cluster_path/kv/wireguard-key" private_key=-
base64 < "$inventory_etc/sa.key" | vault kv put "$cluster_path/kv/k8s/service-account-key" private_key=-

touch "$flag_file"
