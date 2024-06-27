# shellcheck shell=bash disable=SC2154,SC2034
set -euo pipefail

cluster_repository="$(realpath ".")"
group_vars_dir="${cluster_repository}/inventory/yaook-k8s/group_vars"

common_path_prefix="${YAOOK_K8S_VAULT_PATH_PREFIX:-yaook}"
common_policy_prefix="${YAOOK_K8S_VAULT_POLICY_PREFIX:-yaook}"
nodes_approle_name="${YAOOK_K8S_VAULT_NODES_APPROLE_NAME:-${common_path_prefix}/nodes}"
nodes_approle_path="auth/$nodes_approle_name"
k8s_controller_manager_enable_signing_requests="$(
    yq '.k8s_controller_manager_enable_signing_requests
           | if (.|type)=="boolean" then . else error("unset-or-invalid") end' \
          "$group_vars_dir/all/kubernetes.yaml" 2>/dev/null
)" || unset k8s_controller_manager_enable_signing_requests  # unset when unset, invalid or file missing

if [ -n "${cluster:-}" ]; then
    cluster_path="$common_path_prefix/$cluster"

    year="$(date +%Y)"
    ou="$cluster"
    organization="${YAOOK_K8S_CA_ORGANIZATION_OVERRIDE:-A Company that Makes Everything (ACME)}"
    country="${YAOOK_K8S_CA_COUNTRY_OVERRIDE:-DE}"

    ssh_ca_path="$cluster_path/ssh-ca"
    k8s_pki_path="$cluster_path/k8s-pki"
    k8s_front_proxy_pki_path="$cluster_path/k8s-front-proxy-pki"
    etcd_pki_path="$cluster_path/etcd-pki"
fi

# If we can't find the approle accessor, that's ok
nodes_approle_accessor=$(vault read -field="$nodes_approle_name/" -format=json sys/auth | jq -r .accessor) || unset nodes_approle_accessor

function require_vault_token() {
    if [ -z ${VAULT_TOKEN+x} ]; then
        # shellcheck disable=SC2016
        errorf '$VAULT_TOKEN is not set but required during this stage'
        exit 1
    fi
}

function vault_disruption_allowed() {
    [ "${MANAGED_K8S_RELEASE_THE_KRAKEN:-}" = 'true' ]
}

function require_vault_disruption() {
    if ! vault_disruption_allowed; then
        # shellcheck disable=SC2016
        errorf '$MANAGED_K8S_RELEASE_THE_KRAKEN is set to %q' "${MANAGED_K8S_RELEASE_THE_KRAKEN:-}" >&2
        errorf 'aborting since disruptive operations with Vault are not allowed' >&2
        exit 3
    fi
}

function k8s_cluster_ca_backup_destruction {
    [ "${k8s_controller_manager_enable_signing_requests:-false}" != "true" ] \
        && (vault kv get -format=json -mount="$cluster_path/kv" k8s-pki/cluster-root-ca \
            | jq '.data.data // error("unset")' &>/dev/null)
}

function require_k8s_cluster_ca_backup_destruction {
    if k8s_cluster_ca_backup_destruction; then
        require_vault_disruption
        # the destruction is done by the orchestrator hence one must provide a vault token
        require_vault_token
    fi
}

function get_clustername() {
    yq --raw-output '.vault_cluster_name // error("unset")' "${group_vars_dir}/all/vault-backend.yaml"
}

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
    vault secrets enable -path="$etcd_pki_path" pki || $allow_existing
    vault secrets tune -max-lease-ttl="$pki_root_ttl" "$k8s_pki_path"
    vault secrets tune -max-lease-ttl="$pki_root_ttl" "$k8s_front_proxy_pki_path"
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
    vault write "$k8s_pki_path/roles/cluster-admins_admin" \
        max_ttl="$pki_ttl" \
        ttl=72h \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=false \
        organization=kubeadm:cluster-admins \
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
    vault write "$k8s_pki_path/roles/any-cluster-admin" \
        max_ttl="$pki_ttl" \
        ttl="72h" \
        allow_localhost=false \
        enforce_hostnames=false \
        client_flag=true \
        server_flag=false \
        organization=kubeadm:cluster-admins \
        allow_any_name=true \
        allow_bare_domains=true \
        allow_subdomains=false \
        allow_ip_sans=false \
        key=rsa
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

function generate_ca_issuer() {
    local pki_root_ttl="$1"
    local issuer_name="${2:-}"

    if [ -n "$issuer_name" ]; then
        if [ "${k8s_controller_manager_enable_signing_requests:-false}" == "true" ]; then
            vault write -format=json "$k8s_pki_path/root/generate/exported" \
                common_name="Kubernetes Cluster Root CA $year" \
                ou="$ou" \
                organization="$organization" \
                country="$country" \
                ttl="$pki_root_ttl" \
                key_type=ed25519 \
                issuer_name="$issuer_name" \
            | jq --raw-output .data.private_key \
            | vault kv put -mount="$cluster_path/kv" k8s-pki/cluster-root-ca private_key=-
            # ^ Backup the Kubernetes cluster CA key
            # for rollout in the cluster to enable Kubernetes certificate signing
        else
            vault write -format=json "$k8s_pki_path/root/generate/internal" \
                common_name="Kubernetes Cluster Root CA $year" \
                ou="$ou" \
                organization="$organization" \
                country="$country" \
                ttl="$pki_root_ttl" \
                key_type=ed25519 \
                issuer_name="$issuer_name"

            # Destroy all versions of the Kubernetes cluster CA key backup
            vault kv destroy -mount="$cluster_path/kv" \
                -versions="0,$(
                    vault kv metadata get -format=json -mount="$cluster_path/kv" k8s-pki/cluster-root-ca \
                    | jq '.data.versions | keys_unsorted[] |  tonumber' | tr '\n' ','
                )" \
                k8s-pki/cluster-root-ca
        fi

        vault write "$etcd_pki_path/root/generate/internal" \
            common_name="Kubernetes etcd Root CA $year" \
            ou="$ou" \
            organization="$organization" \
            country="$country" \
            ttl="$pki_root_ttl" \
            key_type=ed25519 \
            issuer_name="$issuer_name"

        vault write "$k8s_front_proxy_pki_path/root/generate/internal" \
            common_name="Kubernetes Front Proxy Root CA $year" \
            ou="$ou" \
            organization="$organization" \
            country="$country" \
            ttl="$pki_root_ttl" \
            key_type=ed25519 \
            issuer_name="$issuer_name"
    else
        if [ "${k8s_controller_manager_enable_signing_requests:-false}" == "true" ]; then
            vault write -format=json "$k8s_pki_path/root/generate/exported" \
                common_name="Kubernetes Cluster Root CA $year" \
                ou="$ou" \
                organization="$organization" \
                country="$country" \
                ttl="$pki_root_ttl" \
                key_type=ed25519 \
            | jq --raw-output .data.private_key \
            | vault kv put -mount="$cluster_path/kv" k8s-pki/cluster-root-ca private_key=-
            # ^ Backup the Kubernetes cluster CA key
            # for rollout in the cluster to enable Kubernetes certificate signing
        else
            vault write -format=json "$k8s_pki_path/root/generate/internal" \
                common_name="Kubernetes Cluster Root CA $year" \
                ou="$ou" \
                organization="$organization" \
                country="$country" \
                ttl="$pki_root_ttl" \
                key_type=ed25519

            # Destroy all versions of the Kubernetes cluster CA key backup
            vault kv destroy -mount="$cluster_path/kv" \
                -versions="0,$(
                    vault kv metadata get -format=json -mount="$cluster_path/kv" k8s-pki/cluster-root-ca \
                    | jq '.data.versions | keys_unsorted[] |  tonumber' | tr '\n' ','
                )" \
                k8s-pki/cluster-root-ca
        fi

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
    fi
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
}

function import_cert {
    local chainfile="$1"
    local pkipath="$2"
    local issuer_name="$3"

    response="$(vault write -format=json "$pkipath/intermediate/set-signed" certificate="@$chainfile")"
    issuer="$(jq -r '.data.imported_issuers[0]' <<<"$response")"
    # If this is a no-op update to an existing issuer, the ID is not included
    # in the response. Hence, we can't init it, but we probably also don't have
    # to (because it has been imported before).
    if [ "$issuer" != 'null' ]; then
        vault write "$pkipath/issuer/$issuer" leaf_not_after_behavior=truncate
        # Path issuer name for e.g. root CA rotations
        if [ -n "${issuer_name:-}" ]; then
            echo "patching"
            vault patch "$pkipath/issuer/$issuer" issuer_name="$issuer_name"
        fi
    fi
}

function rotate_pki_issuer() {
    local pki_path="$1"

    vault patch "$pki_path/issuer/default" issuer_name="previous-$(date --iso-8601=date -u)"
    vault write "$pki_path/root/replace" default=next
    vault patch "$pki_path/issuer/next" issuer_name="current"
}

function import_etcd_backup_config() {
    etcdbackup_config_path=config/etcd_backup_s3_config.yaml
    if etcdbackup_config="$(yq --compact-output . "$etcdbackup_config_path")"; then
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
    if [ -f etc/passwordstore/ipsec_eap_psk.gpg ]; then
        if ! vault kv get "$cluster_path"/kv/ipsec-eap-psk > /dev/null; then
            vault kv put "$cluster_path/kv/ipsec-eap-psk" "ipsec_eap_psk=$(PASSWORD_STORE_DIR=etc/passwordstore pass show ipsec_eap_psk)"
            echo "Successfully imported IPSec PSK into vault."
            echo "Removing IPSec PSK from passwordstore."
            rm etc/passwordstore/ipsec_eap_psk.gpg
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

function import_thanos_config() {
    thanos_enabled="$(yq '.monitoring_use_thanos' "${group_vars_dir}/all/prometheus.yaml")"
    manage_thanos_bucket="$(yq '.monitoring_manage_thanos_bucket' "${group_vars_dir}/all/prometheus.yaml")"
    thanos_config_file="$(yq -r '.monitoring_thanos_objectstorage_config_file' "${group_vars_dir}/all/prometheus.yaml")"

    if ! "$thanos_enabled"; then
        echo "Thanos is disabled."
        return;
    fi
    if "$manage_thanos_bucket"; then
        echo "Thanos object storage is configured to be automatically managed"
        return;
    fi
    if vault kv get "$cluster_path"/kv/thanos-config > /dev/null && [ "${thanos_config_file}" == 'None' ]; then
        echo "A Thanos object storage configuration already has been stored in vault."
        echo "There is no k8s-service-layer.prometheus.thanos_objectstorage_config_file configured"
        echo "So it is assumed that configuration should not get updated"
        return
    fi
    if vault kv get "$cluster_path"/kv/thanos-config > /dev/null && [ ! -f "config/$thanos_config_file" ]; then
        echo "A Thanos object storage configuration already has been stored in vault."
        echo "There is no file found at config/$thanos_config_file"
        echo "So it is assumed that configuration should not get updated"
        return
    fi
    if ! vault kv get "$cluster_path"/kv/thanos-config > /dev/null && [ "${thanos_config_file}" == 'None' ]; then
        echo "No configuration stored in vault." >&2
        echo "No Thanos object storage configuration file configured." >&2
        echo "Therefore, failing because automated mangement is also disabled." >&2
        echo "Please check that you configured 'k8s-service-layer.prometheus.thanos_objectstorage_config_file' correctly" >&2
        exit 1
    fi
    if ! vault kv get "$cluster_path"/kv/thanos-config > /dev/null && [ ! -f "config/$thanos_config_file" ]; then
        echo "Failed to find Thanos object storage configuration at config/$thanos_config_file" >&2
        echo "There is also nothing stored in Vault yet." >&2
        echo "Failing because automated mangement is disabled." >&2
        echo "Please check that you configured 'k8s-service-layer.prometheus.thanos_objectstorage_config_file' correctly" >&2
        echo "and config/$thanos_config_file is a valid thanos client configuration" >&2
        exit 1
    fi
    thanos_config="$(yq --compact-output . config/"$thanos_config_file")"
    vault kv put "$cluster_path/kv/thanos-config" - <<<"$thanos_config"
    echo "Successfully imported Thanos object storage configuration into vault."
    echo "Removing Thanos object storage configuration file: config/$thanos_config_file"
    rm "config/$thanos_config_file"
}

function check_for_obsolescences() {
    if [ "$(vault pki health-check -non-interactive -format=json "$cluster_path"/calico-pki/ 2> /dev/null | jq -r '.ca_validity_period[] | .status')" == 'ok' ]; then
        echo "--- WARNING ---"
        echo "The calico pki engine is present"
        echo "although it is obsolete since MR !1084."
        echo "It is recommended to disable it:"
        echo "$ vault secrets disable $cluster_path/calico-pki/"
    fi
}
