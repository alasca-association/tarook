#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")"
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

arg_num=1
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

cluster="$(get_clustername)"
check_clustername "$cluster"
kubernetes_server="$1"
username="vault:$(vault token lookup -format=json | jq -r .data.path)"
kubernetes_version="$(tomlq --raw-output '.kubernetes.version // error("unset")' config/config.toml)"

if [ "$("$actions_dir/../../actions/helpers/semver2.sh" "$kubernetes_version" "1.29")" -lt 0 ]; then
    credentials=$(vault write -format=json yaook/"$cluster"/k8s-pki/issue/any-master common_name="$username" ttl=192h)  # 8 days
    jq --arg "username" "$username" --arg "k8s_server" "$kubernetes_server" '{"apiVersion": "v1", "clusters": [{"cluster": {"certificate-authority-data": .data.issuing_ca | @base64, "server": $k8s_server}, "name": "kubernetes"}], "contexts": [{"context": {"cluster": "kubernetes", "user": $username}, "name": "\($username)@kubernetes"}], "current-context": "\($username)@kubernetes", "kind": "Config", "preferences": {}, "users": [{"name": $username, "user": {"client-certificate-data": .data.certificate | @base64, "client-key-data": .data.private_key | @base64}}]}' <<<"$credentials"
elif [ "$("$actions_dir/../../actions/helpers/semver2.sh" "$kubernetes_version" "1.29")" -gt 0 ]; then
    credentials=$(vault write -format=json yaook/"$cluster"/k8s-pki/issue/any-cluster-admin common_name="$username" ttl=192h)  # 8 days
    jq --arg "username" "$username" --arg "k8s_server" "$kubernetes_server" '{"apiVersion": "v1", "clusters": [{"cluster": {"certificate-authority-data": .data.issuing_ca | @base64, "server": $k8s_server}, "name": "kubernetes"}], "contexts": [{"context": {"cluster": "kubernetes", "user": $username}, "name": "\($username)@kubernetes"}], "current-context": "\($username)@kubernetes", "kind": "Config", "preferences": {}, "users": [{"name": $username, "user": {"client-certificate-data": .data.certificate | @base64, "client-key-data": .data.private_key | @base64}}]}' <<<"$credentials"
else
    errorf 'Version comparison failed'
    exit 2
fi
