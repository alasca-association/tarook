# shellcheck shell=bash disable=SC2154,SC2034
set -euo pipefail
common_path_prefix="${YAOOK_K8S_VAULT_PATH_PREFIX:-yaook}"
common_policy_prefix="${YAOOK_K8S_VAULT_POLICY_PREFIX:-yaook}"
nodes_approle_name="${YAOOK_K8S_VAULT_NODES_APPROLE_NAME:-${common_path_prefix}/nodes}"
nodes_approle_path="auth/$nodes_approle_name"

if [ -n "${cluster:-}" ]; then
    cluster_path="$common_path_prefix/$cluster"

    year="$(date +%Y)"
    ou="$cluster"
    organization="${YAOOK_K8S_CA_ORGANIZATION_OVERRIDE:-A Company that Makes Everything (ACME)}"
    country="${YAOOK_K8S_CA_COUNTRY_OVERRIDE:-DE}"

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
    local allow_existing="${2:-true}"

    if [ "$allow_existing" != 'true' ]; then
        allow_existing=false
    fi

    vault secrets enable -path="$cluster_path/kv" -version=2 kv || $allow_existing
    ( vault secrets enable -path="$ssh_ca_path" ssh && vault write "$ssh_ca_path/config/ca" generate_signing_key=true ) || $allow_existing
    vault secrets enable -path="$k8s_pki_path" pki || $allow_existing
    vault secrets enable -path="$k8s_front_proxy_pki_path" pki || $allow_existing
    vault secrets enable -path="$calico_pki_path" pki || $allow_existing
    vault secrets enable -path="$etcd_pki_path" pki || $allow_existing
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
    vault delete "$k8s_pki_path/roles/system-nodes_admin"
    vault write "$k8s_pki_path/roles/any-master" \
        max_ttl="$pki_ttl" \
        ttl="72h" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=false \
        organization=system:masters \
        allow_any_name=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
        key=rsa
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
        allow_localhost=false \
        enforce_hostnames=false \
        server_flag=false \
        client_flag=true \
        allowed_domains="front-proxy-client" \
        allowed_domains_template=false \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
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

function mkcsrs() {
    local ttl="$1"

    vault write -field=csr "$k8s_pki_path/intermediate/generate/internal" \
        common_name="Kubernetes Cluster Intermediate CA $year" \
        ou="$ou" \
        organization="$organization" \
        country="$country" \
        ttl="$ttl" \
        key_type=ed25519 > k8s-cluster.csr

    vault write -field=csr "$etcd_pki_path/intermediate/generate/internal" \
        common_name="Kubernetes etcd Intermediate CA $year" \
        ou="$ou" \
        organization="$organization" \
        country="$country" \
        ttl="$ttl" \
        key_type=ed25519 > k8s-etcd.csr

    vault write -field=csr "$k8s_front_proxy_pki_path/intermediate/generate/internal" \
        common_name="Kubernetes Front Proxy Intermediate CA $year" \
        ou="$ou" \
        organization="$organization" \
        country="$country" \
        ttl="$ttl" \
        key_type=ed25519 > k8s-front-proxy.csr

    vault write -field=csr "$calico_pki_path/intermediate/generate/internal" \
        common_name="Kubernetes calico Intermediate CA $year" \
        ou="$ou" \
        organization="$organization" \
        country="$country" \
        ttl="$ttl" \
        key_type=ed25519 > k8s-calico.csr
}

function import_etcd_backup_config() {
    etcdbackup_config_path=config/etcd_backup_s3_config.yaml
    if etcdbackup_config="$(python3 -c 'import json, yaml, sys; json.dump(yaml.load(sys.stdin, Loader=yaml.SafeLoader), sys.stdout)' < $etcdbackup_config_path)"; then
        if ! vault kv get "$cluster_path"/kv/etcdbackup > /dev/null; then
            vault kv put "$cluster_path/kv/etcdbackup" - <<<"$etcdbackup_config"
            echo "Successfully imported etcd backup credentials into vault."
            echo "Removing etcd backup credentials file: $etcdbackup_config_path"
            rm $etcdbackup_config_path
        else
            echo "An etcd backup configuration already has been stored in vault."
            echo "Please manually remove the existing data from vault,"
            echo "if you want to import a new configuration file."
        fi
    else
        echo "Failed to find etcd backup credentials at $etcdbackup_config_path" >&2
        echo "Ignoring, as those are optional." >&2
    fi
}

function import_ipsec_eap_psk() {
    if [ -f inventory/.etc/passwordstore/ipsec_eap_psk.gpg ]; then
        if ! vault kv get "$cluster_path"/kv/ipsec-eap-psk > /dev/null; then
            vault kv put "$cluster_path/kv/ipsec-eap-psk" "ipsec_eap_psk=$(PASSWORD_STORE_DIR=inventory/.etc/passwordstore pass show ipsec_eap_psk)"
            echo "Successfully imported IPSec PSK into vault."
            echo "Removing IPSec PSK from passwordstore."
            rm inventory/.etc/passwordstore/ipsec_eap_psk.gpg
        else
            echo "An IPSec PSK already has been stored in vault."
            echo "Please manually remove the existing data from vault,"
            echo "if you want to import the PSK from the passwordstore."
        fi
    else
        echo "Failed to find IPSEC EAP PSK in passwordstore." >&2
        echo "Ignoring, as those are optional." >&2
    fi
}
