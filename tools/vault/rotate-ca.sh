#!/usr/bin/env bash
set -euo pipefail
cluster="$1"
# shellcheck source=tools/vault/lib.sh
# . "$(dirname "$0")/lib.sh"
. managed-k8s/tools/vault/lib.sh

# maximum time for certificates to live: 1 calendar year (leap year compatible)
pki_ttl=8784h
# 5yrs
pki_root_ttl=43830h


new_ca=$(vault write -format=json "$k8s_pki_path/root/generate/internal" \
    common_name="Kubernetes Cluster Root CA $year" \
    ou="$ou" \
    organization="$organization" \
    country="$country" \
    ttl="$pki_root_ttl" \
    key_type=ed25519 | jq -r '.data.issuer_id')

# vault patch yaook/devcluster/k8s-pki/issuer/next issuer_name=
vault patch "yaook/devcluster/k8s-pki/issuer/$new_ca" issuer_name=next >/dev/null
vault write yaook/devcluster/k8s-pki/root/replace default=next >/dev/null
vault patch "yaook/devcluster/k8s-pki/issuer/$new_ca" issuer_name= >/dev/null
