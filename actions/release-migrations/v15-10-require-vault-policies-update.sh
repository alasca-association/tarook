#!/usr/bin/env bash

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

function get_clustername() {
    yq --raw-output '.vault_cluster_name // error("unset")' "${group_vars_dir}/all/vault-backend.yaml"
}

# Check if Vault policies are up-to-date
# so that the ipsec-eap-psk kv secret is not accessible to the orchestrator anymore

vault_token_kind="$( \
  { vault token lookup -non-interactive -format=json 2>/dev/null || true; } \
  | jq --raw-output '
      if type == "object" then (
        .data.policies
        | if index("root") != null then "root"
          elif index("yaook/orchestrator") != null then "orchestrator"
          else "unknown" end
      ) end
    ' \
)"
orchestrator_has_no_cap="$( \
  case "${vault_token_kind}" in
    root|orchestrator)
      if [ "${vault_token_kind}" == "root" ]; then
        notef "Got a Vault token with root policy"
        vault_orchestrator_token="$(vault token create -policy=yaook/orchestrator -field=token)"
      else
        notef "Got a Vault token with yaook/orchestrator policy"
        vault_orchestrator_token="${VAULT_TOKEN:?}"
      fi
      VAULT_TOKEN="${vault_orchestrator_token:?}" \
        vault token capabilities -format=json yaook/"$(get_clustername)"/kv/data/ipsec-eap-psk
      ;;
    unknown)
      notef "Got a Vault token without root or yaook/orchestrator policy"
      echo '[]'
      ;;
    *)
      notef "Got NO Vault token"
      echo '[]'
      ;;
  esac | jq 'index("deny") != null' \
)"

if $orchestrator_has_no_cap; then
  notef "Vault policies look up-to-date"
else
  case "${vault_token_kind}" in
    root)
      notef "Updating Vault policies"
      run "$actions_dir/../tools/vault/init.sh"
      ;;
    orchestrator)
      errorf "Vault policies are not up-to-date"
      # shellcheck disable=SC2016
      notef 'Please run `VAULT_TOKEN=${vault_root_token:?} ./managed-k8s/tools/vault/init.sh`'
      exit 1
      ;;
    *)
      warningf 'Cannot verify that Vault policies are up-to-date'
      # shellcheck disable=SC2016
      warningf 'Please ensure `VAULT_TOKEN=${vault_root_token:?} ./managed-k8s/tools/vault/init.sh` has been executed on this release.'
      ;;
  esac
fi
