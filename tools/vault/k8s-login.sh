#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")/../../actions"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" vault

# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"


while getopts sn flag
do
    case "${flag}" in
        s)
            super_admin=true
            ;;
        n)
            next_issuer=true
            ;;
        *)
            echo "Unknown flag passed: '${flag}'" >&2
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))
[[ "${1:-}" == "--" ]] && shift

arg_num=1
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

load_vars
kubernetes_server="$1"
username="vault:$(vault token lookup -format=json | jq -r .data.path)"

if [ "${super_admin:-false}" == false ]; then
    credentials=$(vault write -format=json yaook/"$cluster"/k8s-pki/issue/any-cluster-admin common_name="$username" exclude_cn_from_sans=true ttl=192h)  # 8 days
    if [ "${next_issuer:-false}" == true ]; then
      next_credentials=$(vault write -format=json yaook/"$cluster"/k8s-pki/issuer/next/issue/any-cluster-admin common_name="$username" exclude_cn_from_sans=true ttl=192h)  # 8 days
    fi
fi

if [ "${super_admin:-false}" == true ]; then
    credentials=$(vault write -format=json yaook/"$cluster"/k8s-pki/issue/any-master common_name="$username" exclude_cn_from_sans=true ttl=192h)  # 8 days
    if [ "${next_issuer:-false}" == true ]; then
      next_credentials=$(vault write -format=json yaook/"$cluster"/k8s-pki/issuer/next/issue/any-master common_name="$username" exclude_cn_from_sans=true ttl=192h)  # 8 days
    fi
fi
jq --slurp --arg "username" "$username" --arg "k8s_server" "$kubernetes_server" '{"apiVersion": "v1", "clusters": [{"cluster": {"certificate-authority-data": [ .[].data.ca_chain | join("\n") ] | join("\n") | @base64, "server": $k8s_server}, "name": "kubernetes"}], "contexts": [ (. | to_entries)[] | {"context": {"cluster": "kubernetes", "user": "\($username)-\(.key)"}, "name": "\($username)-\(.key)@kubernetes"} ], "current-context": "\($username)-0@kubernetes", "kind": "Config", "preferences": {}, "users": [ (. | to_entries)[] | {"name": "\($username)-\(.key)", "user": {"client-certificate-data": ([.value.data.certificate] + .value.data.ca_chain | join("\n")  | @base64), "client-key-data": .value.data.private_key | @base64}} ]}' <<<"${next_credentials:+${next_credentials}$'\n'}${credentials}"
