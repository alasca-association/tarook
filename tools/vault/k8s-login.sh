#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(realpath "$(dirname "$0")")/../../actions"

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh"

# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"


while getopts s flag
do
    case "${flag}" in
        s)
            super_admin=true
            ;;
        *)
            echo "Unknown flag passed: '${flag}'" >&2
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))
[[ "${1}" == "--" ]] && shift

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
kubernetes_version="$(yq --raw-output '.k8s_version // error("unset")' inventory/yaook-k8s/group_vars/all/kubernetes.yaml)"

if [ "${super_admin:-false}" == false ]; then
    credentials=$(vault write -format=json yaook/"$cluster"/k8s-pki/issue/any-cluster-admin common_name="$username" ttl=192h)  # 8 days
fi
# For Kubernetes <= v1.29 we must use any-master
# Drop the OR-condition along with Kubernetes v1.28
if [ "${super_admin:-false}" == true ] || [ "$("$actions_dir/helpers/semver2.sh" "$kubernetes_version" "1.29")" -lt 0 ]; then
    credentials=$(vault write -format=json yaook/"$cluster"/k8s-pki/issue/any-master common_name="$username" ttl=192h)  # 8 days
fi
jq --arg "username" "$username" --arg "k8s_server" "$kubernetes_server" '{"apiVersion": "v1", "clusters": [{"cluster": {"certificate-authority-data": .data.ca_chain | join("\n") | @base64, "server": $k8s_server}, "name": "kubernetes"}], "contexts": [{"context": {"cluster": "kubernetes", "user": $username}, "name": "\($username)@kubernetes"}], "current-context": "\($username)@kubernetes", "kind": "Config", "preferences": {}, "users": [{"name": $username, "user": {"client-certificate-data": ([.data.certificate] + .data.ca_chain | join("\n")  | @base64), "client-key-data": .data.private_key | @base64}}]}' <<<"$credentials"
