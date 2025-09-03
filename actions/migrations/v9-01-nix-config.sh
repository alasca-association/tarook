#!/usr/bin/env bash
set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# migration to Nix based config

pushd "$cluster_repository" >/dev/null || exit 1

config_default="config/default.nix"
config_toml="config/config.toml"

if  [[ -e "$config_toml" ]] && [[ -f "inventory/yaook-k8s/hosts" ]] && \
    ! tomlq --exit-status '.terraform | if has ("enabled") then .enabled else true end' "$config_toml" >/dev/null;
then
    notef "Migrating manual hosts file..."
    if (git ls-files --error-unmatch inventory/yaook-k8s/hosts &> /dev/null); then
      run git mv inventory/yaook-k8s/hosts config/hosts
    else
      run mv inventory/yaook-k8s/hosts config/hosts
      run git add config/hosts
    fi
    notef "Done.\n"
fi

notef "Converting config..."
if ! [[ -e "$config_toml" ]]; then
    if [[ -e "$config_default" ]]; then
        notef "Config already converted"
    else
        warningf "No config found for conversion"
    fi
else
    if [[ -e "$config_default" ]]; then
        errorf "Both ${config_toml} and ${config_default} exist. Aborting due to insonsistent state."
        errorf "Please resolve before re-attempting"
        exit 1
    fi

    cat <<EOF > "$config_default"
{
  pkgs,
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s;
in {
  yk8s = {
      # A reference for all available options can be found at
      # https://yaook.gitlab.io/k8s/devel/user/reference/options/index.html
EOF
    if [[ -e config/hosts ]]; then
        echo "miscellaneous.hosts_file = ./hosts;" >> "$config_default"
    fi
    tomlq -s '
            if .[1].terraform.enabled == false then
                .[1] | del(.terraform) | .openstack.enabled = false
            else
                .[0] * .[1]
            end
        ' "$actions_dir/migrations/v9-01-default.toml" "$config_toml" \
        | nix run github:cloudandheat/json2nix -- --strip-outer-bracket >> "$config_default"
    printf "};}" >> "$config_default"
    nix run nixpkgs#alejandra "$config_default" &>/dev/null
    run git rm "$config_toml"
    run git add config/default.nix
    notef "Done.\n"
fi

notef "Initializing flake..."
run cp "${code_repository}/nix/templates/cluster-repo/flake.nix" .
run git add flake.nix
run nix flake lock
run git add flake.lock
notef "Done.\n"

if [[ -e "config/wireguard_ipam.toml" ]]; then
    notef "Migrating wireguard state..."
    run mkdir -p state/wireguard
    run git mv config/wireguard_ipam.toml state/wireguard/ipam.toml
    notef "Done.\n"
fi

if [[ -d terraform ]]; then
    notef "Migrating terraform state..."
    run mkdir -p state
    if (git ls-files --error-unmatch terraform/ &> /dev/null); then
      run git mv terraform state/terraform
    else
      run mv terraform state/terraform
    fi
    notef "Done.\n"
fi

tf_meta_state=state/terraform/.terraform/terraform.tfstate
if [[ -e "$tf_meta_state" ]] && \
    jq -e '.backend.type == "local"' "$tf_meta_state" >/dev/null
then
    notef "Fixing terraform local backend path..."
    jq '.backend.config.path = "../../state/terraform/terraform.tfstate"' "$tf_meta_state" | sponge "$tf_meta_state"
    notef "Done.\n"
fi

if [[ -d vault ]]; then
    notef "Migrating vault state..."
    if [[ -d state/vault ]]; then
        errorf "./vault and ./state/vault exist. Please clean up inconsistency and try again."
        exit 1
    fi
    run mkdir -p state
    if (git ls-files --error-unmatch vault &> /dev/null); then
      run git mv vault state/vault
    else
      run mv vault state/vault
    fi
    notef "Done.\n"
fi

notef "Auto-fixing the most common Jinja templates in ${config_default} ..."
# shellcheck disable=SC2016
run sed -i 's/{{ scheduling_key_prefix }}/${cfg.node-scheduling.scheduling_key_prefix}/g' "$config_default"
# shellcheck disable=SC2016
run sed -i 's/{{ subnet_cidr }}/${cfg.infra.subnet_cidr}/g' "$config_default"
# shellcheck disable=SC2016
run sed -i 's/"{{ ipsec_proposals }}"/cfg.ipsec.proposals/g' "$config_default"
# shellcheck disable=SC2016
run sed -i 's/{{ vault_cluster_name }}/${cfg.vault.cluster_name}/g' "$config_default"

run sed -i 's/"{{ rook_mon_memory_limit }}"/cfg.k8s-service-layer.rook.mon_resources.limits.memory/g' "$config_default"
run sed -i 's/"{{ rook_osd_memory_limit }}"/cfg.k8s-service-layer.rook.osd_resources.limits.memory/g' "$config_default"
run sed -i 's/"{{ rook_osd_cpu_limit }}"/cfg.k8s-service-layer.rook.osd_resources.limits.cpu/g' "$config_default"
run sed -i 's/"{{ rook_mgr_memory_limit }}"/cfg.k8s-service-layer.rook.mgr_resources.limits.memory/g' "$config_default"
run sed -i 's/"{{ rook_mds_memory_limit }}"/cfg.k8s-service-layer.rook.mds_resources.limits.memory/g' "$config_default"
run sed -i 's/"{{ rook_mds_cpu_limit }}"/cfg.k8s-service-layer.rook.mds_resources.limits.cpu/g' "$config_default"
run sed -i 's/"{{ rook_operator_memory_limit }}"/cfg.k8s-service-layer.rook.operator_resources.limits.memory/g' "$config_default"
run sed -i 's/"{{ rook_operator_cpu_limit }}"/cfg.k8s-service-layer.rook.operator_resources.limits.cpu/g' "$config_default"

run sed -i 's/mon_memory_limit/mon_resources.limits.memory/g' "$config_default"
run sed -i 's/mon_memory_request/mon_resources.requests.memory/g' "$config_default"
run sed -i 's/osd_memory_limit/osd_resources.limits.memory/g' "$config_default"
run sed -i 's/osd_memory_request/osd_resources.requests.memory/g' "$config_default"
run sed -i 's/mgr_memory_limit/mgr_resources.limits.memory/g' "$config_default"
run sed -i 's/mgr_memory_request/mgr_resources.requests.memory/g' "$config_default"
run sed -i 's/mds_memory_limit/mds_resources.limits.memory/g' "$config_default"
run sed -i 's/mds_memory_request/mds_resources.requests.memory/g' "$config_default"
run sed -i 's/operator_memory_limit/operator_resources.limits.memory/g' "$config_default"
run sed -i 's/operator_memory_request/operator_resources.requests.memory/g' "$config_default"

run sed -i 's/"{{ monitoring_alertmanager_memory_limit }}"/cfg.k8s-service-layer.monitoring.alertmanager_resources.limits.memory/g' "$config_default"
run sed -i 's/"{{ monitoring_alertmanager_cpu_limit }}"/cfg.k8s-service-layer.monitoring.alertmanager_resources.limits.cpu/g' "$config_default"
run sed -i 's/"{{ monitoring_prometheus_memory_limit }}"/cfg.k8s-service-layer.monitoring.prometheus_resources.limits.memory/g' "$config_default"
run sed -i 's/"{{ monitoring_prometheus_cpu_limit }}"/cfg.k8s-service-layer.monitoring.prometheus_resources.limits.cpu/g' "$config_default"
run sed -i 's/"{{ monitoring_thanos_sidecar_memory_limit }}"/cfg.k8s-service-layer.monitoring.thanos_resources.limits.memory/g' "$config_default"
run sed -i 's/"{{ monitoring_thanos_sidecar_cpu_limit }}"/cfg.k8s-service-layer.monitoring.thanos_resources.limits.cpu/g' "$config_default"

run sed -i 's/alertmanager_memory_limit/alertmanager_resources.limits.memory/g' "$config_default"
run sed -i 's/alertmanager_memory_request/alertmanager_resources.requests.memory/g' "$config_default"
run sed -i 's/prometheus_memory_limit/prometheus_resources.limits.memory/g' "$config_default"
run sed -i 's/prometheus_memory_request/prometheus_resources.requests.memory/g' "$config_default"
run sed -i 's/thanos_sidecar_memory_limit/thanos_sidecar_resources.limits.memory/g' "$config_default"
run sed -i 's/thanos_sidecar_memory_request/thanos_sidecar_resources.requests.memory/g' "$config_default"

notef "Done.\n"

jinja_templates="$(grep -nP '{{\s*.*\s*}}' "$config_default" || [[ $? -eq 1 ]])" # ignore exit code 1 meaning no matches found
if [[ -n "$jinja_templates" ]]; then
    hintf "!!MANUAL ACTION REQUIRED!!"
    cat <<EOF
Jinja templates in config values are not supported anymore. Please replace them with the equivalent Nix expression.
Inside ${config_default}, all available options can be accessed using the attribute set called cfg.
In many cases, recursive attribute sets can be used to re-use adjacent values, eg.

rook = rec {
    mds_memory_limit = "4Gi";
    mds_memory_request = mds_memory_limit;
    ...

Inside strings, variables can be referred to with \${variablename}.
Eg.: {{ scheduling_key_prefix }} has already been replaced by \${cfg.node-scheduling.scheduling_key_prefix} for you.
All available options: https://yaook.gitlab.io/k8s/release/v${version_major_minor}/user/reference/options/index.html

Please fixup ${config_default} and retry

EOF

    errorf "Jinja templates that need to be replaced inside $config_default:"
    echo "$jinja_templates"
    exit 1
fi

notef "\nConfig migration done!"

notef "Rebuilding inventory..."
run rm -rf inventory
run "$actions_dir/update-inventory.sh"
run git add "$config_default"

popd >/dev/null || exit 1
