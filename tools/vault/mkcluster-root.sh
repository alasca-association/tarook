#!/bin/bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

# maximum time for certificates to live: 1 calendar year (leap year compatible)
pki_ttl=8784h
# 5yrs
pki_root_ttl=43830h

init_cluster_secrets_engines "$pki_root_ttl"

vault write "$k8s_pki_path/root/generate/internal" \
    common_name="Kubernetes Cluster Root CA $year" \
    ou="$ou" \
    organization="$organization" \
    country="$country" \
    ttl="$pki_root_ttl" \
    key_type=ed25519

vault write "$etcd_pki_path/root/generate/internal" \
    common_name="Kubernetes etcd Root CA $year" \
    ou="$ou" \
    organization="$organization" \
    country="$country" \
    ttl="$pki_root_ttl" \
    key_type=ed25519

vault write "$k8s_front_proxy_pki_path/root/generate/internal" \
    common_name="Kubernetes Front Proxy Root CA $year" \
    ou="$ou" \
    organization="$organization" \
    country="$country" \
    ttl="$pki_root_ttl" \
    key_type=ed25519

vault write "$calico_pki_path/root/generate/internal" \
    common_name="Kubernetes calico Root CA $year" \
    ou="$ou" \
    organization="$organization" \
    country="$country" \
    ttl="$pki_root_ttl" \
    key_type=ed25519

init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"
init_k8s_calico_pki_roles "$calico_pki_path" "$pki_ttl"

echo "-----------------------------------------------"
echo "Trying to importing etcd backup credentials ..."
import_etcd_backup_config
