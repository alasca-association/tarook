#!/usr/bin/env bash
set -euo pipefail
cluster="$1"
action="${2:-prepare}"
# shellcheck source=tools/vault/lib.sh
# . "$(dirname "$0")/lib.sh"
. managed-k8s/tools/vault/lib.sh

# 5yrs
pki_root_ttl=43830h

case "$action" in
    "prepare")
    vault write -format=json "$k8s_pki_path/root/generate/internal" \
        common_name="Kubernetes Cluster Root CA $year" \
        ou="$ou" \
        organization="$organization" \
        country="$country" \
        ttl="$pki_root_ttl" \
        key_type=ed25519 \
        issuer_name=next
    vault patch "yaook/devcluster/k8s-pki/issuer/prev" issuer_name= >/dev/null || true
    ;;
    "apply")
    vault patch "yaook/devcluster/k8s-pki/issuer/default" issuer_name=prev >/dev/null
    vault write yaook/devcluster/k8s-pki/root/replace default=next >/dev/null
    vault patch "yaook/devcluster/k8s-pki/issuer/next" issuer_name= >/dev/null
    ;;
    *)
    echo "Usage $0 <clustername> [prepare|apply]"
    ;;
esac
