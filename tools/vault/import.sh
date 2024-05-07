#!/usr/bin/env bash
set -euo pipefail

# Ensure that the latest config is deployed to the inventory
nix run .#update-inventory

# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

function usage() {
    echo "usage: $0 [no-intermediates|with-intermediates]" >&2
    echo >&2
    echo "Arguments:" >&2
    echo "    no-intermediates" >&2
    echo "        Import the existing root CA keys into Vault directly as if" >&2
    echo "        using mkcluster-root.sh" >&2
    echo "    with-intermediates" >&2
    echo "        Do not import the existing root CA keys, requiring you to" >&2
    echo "        use them to issue intermediates using them as if using" >&2
    echo "        mkcluster-intermediate.sh" >&2
}

arg_num=1
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

cluster="$(get_clustername)"
check_clustername "$cluster"
mode="$1"

import_roots=1
case "$mode" in
    no-intermediates)
        # 5yrs
        pki_ca_ttl=43830h
        ;;
    with-intermediates)
        import_roots=0
        # 1.5yrs
        pki_ca_ttl=13176h
        ;;
    *)
        usage
        exit 2
        ;;
esac

# reload the lib to update the vars after initializing the clustername
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"
scriptdir="$(dirname "$0")"

inventory_etc=etc
flag_file="$inventory_etc/migrated-to-vault"
wg_usage="$(yq '.enabled // true' inventory/yaook-k8s/group_vars/gateways/wireguard.yaml)"

if [ ! -d 'etc' ]; then
    echo "$0: ./etc does not exist. are you running this from the right place?" >&2
    exit 1
fi

if [ -e "$flag_file" ]; then
    echo "$0: presence of $flag_file indicates that migration has already happened." >&2
    echo "$0: refusing to continue." >&2
    exit 2
fi

if [ ! -e 'etc/passwordstore/wg_gw_key.gpg' ] && [ "${wg_usage:-true}" == 'true' ]; then
    echo "$0: couldn't find wg_gw_key.gpg despite wireguard.enabled being set to true" >&2
    echo "$0: refusing to continue, this does not look like an up-to-date, spawned cluster" >&2
    exit 2
fi

if [ ! -e 'etc/sa.key' ]; then
    echo "$0: couldn't find sa.key" >&2
    echo "$0: refusing to continue, this does not look like an up-to-date, spawned cluster" >&2
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
upgrade_ca "$inventory_etc/etcd/ca.crt" "$inventory_etc/etcd/ca.key"

pki_ttl=8784h

init_cluster_secrets_engines "$pki_ca_ttl" 'false'

if [ "$import_roots" -eq 1 ]; then
    echo "Importing CA bundles ..."

    cat "$inventory_etc/ca.crt" "$inventory_etc/ca.key" | vault write "$k8s_pki_path/config/ca" pem_bundle=-
    cat "$inventory_etc/front-proxy-ca.crt" "$inventory_etc/front-proxy-ca.key" | vault write "$k8s_front_proxy_pki_path/config/ca" pem_bundle=-
    cat "$inventory_etc/etcd/ca.crt" "$inventory_etc/etcd/ca.key" | vault write "$etcd_pki_path/config/ca" pem_bundle=-
else
    echo "NOT importing CA bundles because invoked with with-intermediates"
    echo "  Make sure to sign the CSRs and load the signed certificates using"
    echo "  load-signed-intermediates.sh"

    mkcsrs "$pki_ca_ttl"

    echo "NOTE: CSRs have been written to k8s-{cluster,etcd,front-proxy}.csr."
fi

echo "Importing other secrets ..."

if [ "${wg_usage:-true}" == 'true' ]; then
PASSWORD_STORE_DIR="$inventory_etc/passwordstore" pass show wg_gw_key | head -n1 | tr -d '\n' | vault kv put "$cluster_path/kv/wireguard-key" private_key=-
base64 < "$inventory_etc/sa.key" | vault kv put "$cluster_path/kv/k8s/service-account-key" private_key=-
fi

echo "Initializing PKI engines ..."

init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"

echo "-----------------------------------------------"
echo "Trying to importing etcd backup credentials ..."
import_etcd_backup_config

touch "$flag_file"
