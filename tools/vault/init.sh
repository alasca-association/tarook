#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

if [ -z "${nodes_approle_accessor:-}" ]; then
    echo "approle auth at $nodes_approle_name not initialized yet, creating"
    vault auth enable -path="$nodes_approle_name" approle
fi

# reload the lib to update the vars after initializing the approle
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"


function write_policy() {
    name="$1"
    vault policy write "$common_policy_prefix/$name" -
}

write_policy k8s-control-plane <<EOF
path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/kv/data/k8s/join-key" {
    capabilities = ["create", "update"]
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/kv/data/k8s/service-account-key" {
    capabilities = ["create", "update", "read"]
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/k8s-pki/issue/system-masters_admin" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        # common name is enforced by the PKI role config
        "common_name" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/k8s-pki/issue/system-masters_apiserver" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        # common name is enforced by the PKI role config
        "common_name" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/k8s-pki/issue/system-masters_controllers" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        # common name is enforced by the PKI role config
        "common_name" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/k8s-pki/issue/apiserver" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
        "alt_names" = [],
        "ip_sans" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/etcd-pki/issue/server" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
        "alt_names" = [],
        "ip_sans" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/etcd-pki/issue/peer" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
        "alt_names" = [],
        "ip_sans" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/etcd-pki/issue/healthcheck" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
        "alt_names" = [],
        "ip_sans" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/etcd-pki/issue/kube-apiserver" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
        "alt_names" = [],
        "ip_sans" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/k8s-front-proxy-pki/issue/apiserver" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/calico-pki/issue/node" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/calico-pki/issue/typha" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
    }
}
EOF

write_policy k8s-node <<EOF
path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/kv/data/k8s/join-key" {
    capabilities = ["read"]
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/k8s-pki/issue/system-nodes_node" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        # common name is enforced by the PKI role config
        "common_name" = []
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/k8s-pki/issue/calico-cni" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = [],
    }
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/k8s-pki/cert/ca_chain" {
    capabilities = ["read"]
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/etcd-pki/cert/ca_chain" {
    capabilities = ["read"]
}

path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/calico-pki/cert/ca_chain" {
    capabilities = ["read"]
}
EOF

write_policy gateway <<EOF
path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/kv/data/wireguard-key" {
    capabilities = ["create", "update", "read"]
}
EOF

write_policy node <<EOF
path "$common_path_prefix/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.yaook_deployment }}/ssh-ca/sign/{{ identity.entity.aliases.$nodes_approle_accessor.metadata.role_name }}" {
    capabilities = ["create", "update"]
}
EOF

write_policy orchestrator <<EOF
path "$common_path_prefix/+/ssh-ca/roles/+" {
    capabilities = ["delete"]
}

path "$common_path_prefix/+/ssh-ca/roles/+" {
    capabilities = ["create", "update"]
    required_parameters = ["key_type", "ttl", "allow_host_certificates", "allow_bare_domains", "allowed_domains", "algorithm_signer"]
    allowed_parameters = {
        "key_type" = ["ca"],
        "ttl" = [],
        "allow_host_certificates" = ["true"],
        "allow_bare_domains" = ["true"],
        "allowed_domains" = [],
        "algorithm_signer" = [],
    }
}

path "$nodes_approle_path/role/+" {
    capabilities = ["create", "update"]
    required_parameters = ["token_ttl", "token_max_ttl", "token_policies", "token_no_default_policy", "token_type"]
    allowed_parameters = {
        "token_ttl" = [],
        "token_max_ttl" = ["1h"],
        "token_policies" = [
            "$common_policy_prefix/k8s-control-plane,$common_policy_prefix/k8s-node,$common_policy_prefix/node",
            "$common_policy_prefix/k8s-control-plane,$common_policy_prefix/k8s-node,$common_policy_prefix/gateway,$common_policy_prefix/node",
            "$common_policy_prefix/gateway,$common_policy_prefix/node",
            "$common_policy_prefix/k8s-node,$common_policy_prefix/node",
        ],
        "token_no_default_policy" = ["false"],
        "token_type" = ["service"],
    }
}

path "$nodes_approle_path/role/+" {
    capabilities = ["delete"]
}

path "$nodes_approle_path/role/+/role-id" {
    capabilities = ["read"]
}

path "$nodes_approle_path/role/+/secret-id" {
    capabilities = ["create", "update"]
    required_parameters = ["metadata"]
    allowed_parameters = {
        "metadata" = [],
    }
    min_wrapping_ttl = "60s"
    max_wrapping_ttl = "3h"
}

path "$nodes_approle_path/role/+/secret-id/destroy" {
    capabilities = ["create", "update"]
}

path "$common_path_prefix/+/k8s-pki/issue/system-nodes_admin" {
    capabilities = ["create", "update"]
    required_parameters = ["common_name", "ttl"]
    allowed_parameters = {
        "ttl" = [],
        "common_name" = []
    }
}

path "$common_path_prefix/+/kv/data/ipmi/*" {
    capabilities = ["read"]
}

path "$common_path_prefix/+/kv/data/etcdbackup" {
    capabilities = ["read"]
}

path "$common_path_prefix/+/kv/data/wireguard-key" {
    capabilities = ["create", "update", "read"]
}
EOF
