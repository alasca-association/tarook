#!/bin/bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"
scriptdir="$(dirname "$0")"

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

echo "NOTE: This script is only intended to be used for non-IaaS clusters."
echo "Use with C&H IaaS clusters is **not compliant** with policies."

read -r -p 'I read the above notice and still want to continue? [N/y]' choice

case "$choice" in
    y|Y)
        ;;
    *)
        echo "User denied consent, exiting. (like the good cookie banner I am)"
        exit 127
        ;;
esac

echo "Preparing CAs for use with Vault ..."

function upgrade_ca() {
    crt="$1"
    key="$2"
    bak="$crt.bak"
    mv --no-clobber "$crt" "$bak"
    bash "$scriptdir/reshape-ca.sh" "$bak" "$key" "$crt"
}

upgrade_ca "$inventory_etc/ca.crt" "$inventory_etc/ca.key"
upgrade_ca "$inventory_etc/front-proxy-ca.crt" "$inventory_etc/front-proxy-ca.key"
upgrade_ca "$inventory_etc/calico/typhaca.crt" "$inventory_etc/calico/typhaca.key"
upgrade_ca "$inventory_etc/etcd/ca.crt" "$inventory_etc/etcd/ca.key"

pki_ttl=8784h
pki_root_ttl=43830h

init_cluster_secrets_engines "$pki_root_ttl" 'false'

echo "Importing CA bundles ..."

cat "$inventory_etc/ca.crt" "$inventory_etc/ca.key" | vault write "$k8s_pki_path/config/ca" pem_bundle=-
cat "$inventory_etc/front-proxy-ca.crt" "$inventory_etc/front-proxy-ca.key" | vault write "$k8s_front_proxy_pki_path/config/ca" pem_bundle=-
cat "$inventory_etc/calico/typhaca.crt" "$inventory_etc/calico/typhaca.key" | vault write "$calico_pki_path/config/ca" pem_bundle=-
cat "$inventory_etc/etcd/ca.crt" "$inventory_etc/etcd/ca.key" | vault write "$etcd_pki_path/config/ca" pem_bundle=-

echo "Importing other secrets ..."

PASSWORD_STORE_DIR="$inventory_etc/passwordstore" pass show wg_gw_key | head -n1 | tr -d '\n' | vault kv put "$cluster_path/kv/wireguard-key" private_key=-
base64 < "$inventory_etc/sa.key" | vault kv put "$cluster_path/kv/k8s/service-account-key" private_key=-

echo "Importing etcd backup credentials ..."

etcdbackup_config_path=config/etcd_backup_s3_config.yaml
if etcdbackup_config="$(python3 -c 'import json, yaml, sys; yaml.dump(json.load(sys.stdin), sys.stdout)' < $etcdbackup_config_path)"; then
    vault kv put "$cluster_path/kv/etcdbackup" @- <<<"$etcdbackup_config"
else
    echo "Failed to find etcd backup credentials at $etcdbackup_config_path" >&2
    echo "Ignoring, as those are optional." >&2
    echo "If you did not expect this, make sure to store the credentials in vault at" >&2
    echo "    $cluster_path/kv/etcdbackup" >&2
fi

echo "Initializing PKI engines ..."

init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"
init_k8s_calico_pki_roles "$calico_pki_path" "$pki_ttl"

touch "$flag_file"
