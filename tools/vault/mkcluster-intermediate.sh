#!/bin/bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

# maximum time for certificates to live: 1 calendar year (leap year compatible)
pki_ttl=8784h
# 1.5yrs
pki_intermediate_ttl=13176h

init_cluster_secrets_engines "$pki_intermediate_ttl"

year="$(date +%Y)"

vault write -field=csr "$k8s_pki_path/intermediate/generate/internal" \
    common_name="$cluster Kubernetes Cluster Intermediate CA $year" \
    ttl="$pki_intermediate_ttl" \
    key_type=ed25519 > k8s-cluster.csr

vault write -field=csr "$etcd_pki_path/intermediate/generate/internal" \
    common_name="$cluster Kubernetes etcd Intermediate CA $year" \
    ttl="$pki_intermediate_ttl" \
    key_type=ed25519 > k8s-etcd.csr

vault write -field=csr "$k8s_front_proxy_pki_path/intermediate/generate/internal" \
    common_name="$cluster Kubernetes Front Proxy Intermediate CA $year" \
    ttl="$pki_intermediate_ttl" \
    key_type=ed25519 > k8s-front-proxy.csr

vault write -field=csr "$calico_pki_path/intermediate/generate/internal" \
    common_name="$cluster Kubernetes calico Intermediate CA $year" \
    ttl="$pki_intermediate_ttl" \
    key_type=ed25519 > k8s-calico.csr

init_k8s_cluster_pki_roles "$k8s_pki_path" "$pki_ttl"
init_k8s_etcd_pki_roles "$etcd_pki_path" "$pki_ttl"
init_k8s_front_proxy_pki_roles "$k8s_front_proxy_pki_path" "$pki_ttl"
init_k8s_calico_pki_roles "$calico_pki_path" "$pki_ttl"

echo "NOTE: CSRs have been written to k8s-{cluster,etcd,front-proxy,calico}.csr."
