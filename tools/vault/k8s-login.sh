#!/usr/bin/env bash
set -euo pipefail
clustername="$1"
kubernetes_server="$2"
username="ldap:$(vault token lookup -format=json | jq -r .data.meta.username)"
credentials=$(vault write -format=json yaook/"$clustername"/k8s-pki/issue/admin-user common_name="$username" ttl=192h)  # 8 days
jq --arg "username" "$username" --arg "k8s_server" "$kubernetes_server" '{"apiVersion": "v1", "clusters": [{"cluster": {"certificate-authority-data": .data.issuing_ca | @base64, "server": $k8s_server}, "name": "kubernetes"}], "contexts": [{"context": {"cluster": "kubernetes", "user": $username}, "name": "\($username)@kubernetes"}], "current-context": "\($username)@kubernetes", "kind": "Config", "preferences": {}, "users": [{"name": $username, "user": {"client-certificate-data": .data.certificate | @base64, "client-key-data": .data.private_key | @base64}}]}' <<<"$credentials"
