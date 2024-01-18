#!/usr/bin/env bash
set -euo pipefail
cluster="$1"
ldap_accessor="$2"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

function write_policy() {
    name="$1"
    vault policy write "$common_policy_prefix/$name" -
}

write_policy k8s-ldap-admin <<EOF
path "$common_path_prefix/+/k8s-pki/issue/admin-user" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        # common name is enforced by the PKI role config
        "common_name" = []
    }
}
EOF

vault write "$k8s_pki_path/roles/admin-user" \
  max_ttl="720h" \
  ttl="72h" \
  allow_localhost=false \
  enforce_hostnames=false \
  client_flag=true \
  server_flag=false \
  organization=system:masters \
  allowed_domains="ldap:{{ identity.entity.aliases.$ldap_accessor.name }}" \
  allowed_domains_template=true \
  allow_bare_domains=true \
  allow_subdomains=false \
  allow_ip_sans=false \
  key=rsa
