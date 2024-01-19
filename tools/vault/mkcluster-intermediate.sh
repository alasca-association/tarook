#!/usr/bin/env bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

# maximum time for certificates to live: 1 calendar year (leap year compatible)
pki_ttl=8784h
# 1.5yrs
pki_intermediate_ttl=13176h

init_cluster_secrets_engines "$pki_intermediate_ttl"

mkcsrs "$pki_intermediate_ttl"

init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"
init_k8s_calico_pki_roles "$calico_pki_path" "$pki_ttl"

echo "NOTE: CSRs have been written to k8s-{cluster,etcd,front-proxy,calico}.csr."

echo "-----------------------------------------------"
echo "Trying to importing etcd backup credentials ..."
import_etcd_backup_config

echo "-----------------------------------------------"
echo "Trying to import IPSec EAP PSK ..."
import_ipsec_eap_psk

echo "-----------------------------------------------"
echo "Trying to import Thanos S3 config ..."
import_thanos_config
