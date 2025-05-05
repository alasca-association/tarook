#!/usr/bin/env bash
set -euo pipefail
#
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

arg_num=1
if [ "$#" -ne "$arg_num" ]; then
    echo "ERROR: Expecting $arg_num argument(s), but $# were given" >&2
    echo >&2
    exit 2
fi

new_cluster="$1"
cluster="$(get_clustername)"
check_clustername "$new_cluster" cmdline
check_clustername "$cluster" config

# reload the lib to update the vars after initializing the clustername
# shellcheck source=tools/vault/lib.sh
. "$(dirname "$0")/lib.sh"

set_cluster_specific_variables "$new_cluster" new_cluster_path=cluster_path
# shellcheck disable=SC2154

for kv_secret_ref in "${vault_kv_secret_refs[@]}"; do
    dir_suffix='/*'

    # Resolve kv secret ref
    case "${kv_secret_ref}" in
        "wireguard/wg*-key")
            readarray -t kv_secret_names < <(
                tomlq --raw-output \
                    '.wireguard.endpoints[] | "wireguard/wg\(.id)-key"' \
                    "$config_file" \
                | grep 'wireguard/wg.*-key'
            )
            ;;
        *"${dir_suffix}")
            readarray -t kv_secret_names < <(
                vault kv list \
                    -format=json \
                    -mount="${cluster_path}/kv" \
                    "${kv_secret_ref%"${dir_suffix}"}" \
                    | jq -r '.[] | "'"${kv_secret_ref%"${dir_suffix}"}"'/\(.)"'
            )
            ;;
        *)
            if err="$( \
                2>&1 >/dev/null \
                vault kv get -mount="${cluster_path}/kv" "${kv_secret_ref}" \
            )"; then
                declare -a kv_secret_names=( "${kv_secret_ref}" )
            else
                >&2 printf "Secret '%s' not found. Skipping.\n  ╰ %s\n" \
                    "${kv_secret_ref}" "${err}"
                declare -a kv_secret_names=( )
            fi
            ;;
    esac

    # Download secrets from old path and reupload to new path
    for kv_secret_name in "${kv_secret_names[@]}"; do
        >&2 printf "Copying secret '%s': '%s/kv' -> '%s/kv' ..." \
            "${kv_secret_name}" "${cluster_path}" "${new_cluster_path}"
        if err="$(
            vault kv get -format=json \
                -mount="${cluster_path}/kv" "${kv_secret_name}" \
            | jq '.data.data' \
            | vault kv put \
                -mount="${new_cluster_path}/kv" "${kv_secret_name}" \
                - \
                2>&1 >/dev/null
        )"; then
          printf 'done\n'
        else
          printf 'failed\n  ╰ %s\n' "${err}"
        fi
    done
done
