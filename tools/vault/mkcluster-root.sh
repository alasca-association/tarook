#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")/../../actions"

# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

arg_num=1
if [ "$#" -gt "$arg_num" ]; then
    echo "ERROR: Expecting at most $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

if [ "${1:+x}" == "x" ]; then
    # clustername given as argument
    cluster="$1"
    confirm_clustername "$cluster"
else
    # use configured clustername
    cluster="$(get_clustername)"
fi

# reload the lib to update the vars after initializing the clustername
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

# maximum time for certificates to live: 1 calendar year (leap year compatible)
pki_ttl=8784h
# 5yrs
pki_root_ttl=43830h

# Require permission when Kubernetes cluster CA backup is going to be destroyed
# by generate_ca_issuer()
require_k8s_cluster_ca_backup_destruction

init_cluster_secrets_engines "$pki_root_ttl"

generate_ca_issuer "$pki_root_ttl"

init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"

echo "-----------------------------------------------"
echo "Trying to import etcd backup credentials ..."
import_etcd_backup_config

echo "-----------------------------------------------"
echo "Trying to import IPSec EAP PSK ..."
import_ipsec_eap_psk

echo "-----------------------------------------------"
echo "Trying to import Thanos S3 config ..."
import_thanos_config

echo "-----------------------------------------------"
echo "Trying to import Vault backup config ..."
import_vault_backup_s3_config

echo "-----------------------------------------------"
echo "Checking for obsolescences"
check_for_obsolescences
