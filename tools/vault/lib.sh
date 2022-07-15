# shellcheck shell=bash disable=SC2154,SC2034
set -euo pipefail
common_path_prefix="${YAOOK_K8S_VAULT_PATH_PREFIX:-yaook}"
common_policy_prefix="${YAOOK_K8S_VAULT_POLICY_PREFIX:-yaook}"
nodes_approle_name="${YAOOK_K8S_VAULT_NODES_APPROLE_NAME:-${common_path_prefix}/nodes}"
nodes_approle_path="auth/$nodes_approle_name"

year="$(date +%Y)"
ou="$cluster"
organization="${YAOOK_K8S_CA_ORGANIZATION_OVERRIDE:-CLOUD&HEAT Technologies GmbH}"
country="${YAOOK_K8S_CA_COUNTRY_OVERRIDE:-DE}"

if [ -n "${cluster:-}" ]; then
    cluster_path="$common_path_prefix/$cluster"

    ssh_ca_path="$cluster_path/ssh-ca"
    k8s_pki_path="$cluster_path/k8s-pki"
    k8s_front_proxy_pki_path="$cluster_path/k8s-front-proxy-pki"
    calico_pki_path="$cluster_path/calico-pki"
    etcd_pki_path="$cluster_path/etcd-pki"
fi

# If we can't find the approle accessor, that's ok
nodes_approle_accessor=$(vault read -field="$nodes_approle_name/" -format=json sys/auth | jq -r .accessor) || unset nodes_approle_accessor

function init_cluster_secrets_engines() {
    local pki_root_ttl="$1"

    vault secrets enable -path="$cluster_path/kv" -version=2 kv || true
    ( vault secrets enable -path="$ssh_ca_path" ssh && vault write "$ssh_ca_path/config/ca" generate_signing_key=true ) || true
    vault secrets enable -path="$k8s_pki_path" pki || true
    vault secrets enable -path="$k8s_front_proxy_pki_path" pki || true
    vault secrets enable -path="$calico_pki_path" pki || true
    vault secrets enable -path="$etcd_pki_path" pki || true
    vault secrets tune -max-lease-ttl="$pki_root_ttl" "$k8s_pki_path"
    vault secrets tune -max-lease-ttl="$pki_root_ttl" "$k8s_front_proxy_pki_path"
    vault secrets tune -max-lease-ttl="$pki_root_ttl" "$calico_pki_path"
    vault secrets tune -max-lease-ttl="$pki_root_ttl" "$etcd_pki_path"
}

function init_k8s_cluster_pki_roles() {
    local k8s_pki_path="$1"
    local pki_ttl="$2"

    vault write "$k8s_pki_path/roles/system-masters_admin" \
        max_ttl="$pki_ttl" \
        ttl=72h \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=false \
        organization=system:masters \
        allow_any_name=true \
        require_cn=false \
        allow_ip_sans=false \
        key_type=rsa
    vault write "$k8s_pki_path/roles/system-masters_apiserver" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=false \
        organization=system:masters \
        allowed_domains="apiserver:{{identity.entity.aliases.$nodes_approle_accessor.metadata.role_name}}" \
        allowed_domains_template=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
        key_type=rsa
    vault write "$k8s_pki_path/roles/apiserver" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=true \
        enforce_hostnames=true \
        server_flag=true \
        allow_any_name=true \
        allow_ip_sans=true \
        key_type=rsa
    vault write "$k8s_pki_path/roles/system-masters_controllers" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=false \
        allowed_domains="system:kube-controller-manager,system:kube-scheduler" \
        allowed_domains_template=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
        key_type=rsa
    vault write "$k8s_pki_path/roles/system-nodes_node" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=true \
        organization=system:nodes \
        allowed_domains="system:node:{{identity.entity.aliases.$nodes_approle_accessor.metadata.role_name}},{{identity.entity.aliases.$nodes_approle_accessor.metadata.role_name}},system:node:{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_hostname}},{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_hostname}}" \
        allowed_domains_template=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
        key_type=rsa
    vault write "$k8s_pki_path/roles/system-nodes_admin" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=true \
        organization=system:nodes \
        allow_any_name=true \
        key_type=rsa
    vault write "$k8s_pki_path/roles/calico-cni" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=false \
        allowed_domains="calico-cni" \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
        key_type=rsa
}

function init_k8s_etcd_pki_roles() {
    local etcd_pki_path="$1"
    local pki_ttl="$2"

    vault write "$etcd_pki_path/roles/server" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=true \
        enforce_hostnames=true \
        client_flag=true \
        server_flag=true \
        allowed_domains="{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_hostname}},127.0.0.1,::1,{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_primary_ipv4}},{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_primary_ipv6}},localhost" \
        allowed_domains_template=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        key_type=rsa
    vault write "$etcd_pki_path/roles/peer" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=true \
        enforce_hostnames=true \
        client_flag=true \
        server_flag=true \
        allowed_domains="{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_hostname}},127.0.0.1,::1,{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_primary_ipv4}},{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_primary_ipv6}},localhost" \
        allowed_domains_template=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        key_type=rsa
    vault write "$etcd_pki_path/roles/healthcheck" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=true \
        client_flag=true \
        server_flag=false \
        allowed_domains="{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_hostname}},{{identity.entity.aliases.$nodes_approle_accessor.metadata.role_name}}" \
        allowed_domains_template=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        key_type=rsa
    vault write "$etcd_pki_path/roles/kube-apiserver" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=true \
        client_flag=true \
        server_flag=false \
        organization=system:masters \
        allowed_domains="{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_hostname}},{{identity.entity.aliases.$nodes_approle_accessor.metadata.role_name}}" \
        allowed_domains_template=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        key_type=rsa
}

function init_k8s_front_proxy_pki_roles() {
    local k8s_front_proxy_pki_path="$1"
    local pki_ttl="$2"

    vault write "$k8s_front_proxy_pki_path/roles/apiserver" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=true \
        enforce_hostnames=true \
        server_flag=false \
        client_flag=true \
        allowed_domains="{{identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_hostname}},{{identity.entity.aliases.$nodes_approle_accessor.metadata.role_name}}" \
        allowed_domains_template=true \
        allow_any_name=true \
        allow_ip_sans=true \
        key_type=rsa
}

function init_k8s_calico_pki_roles() {
    local calico_pki_path="$1"
    local pki_ttl="$2"

    vault write "$calico_pki_path/roles/node" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=true \
        allowed_domains="calico-node" \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
        key_type=rsa
    vault write "$calico_pki_path/roles/typha" \
        max_ttl="$pki_ttl" \
        ttl="$pki_ttl" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=true \
        allowed_domains="calico-typha" \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
        key_type=rsa
}
