#!/usr/bin/env bash
set -euo pipefail
if [ "${WG_USAGE:-true}" == "true" ]; then
    actions_dir="$(dirname "$0")"
    # shellcheck source=actions/lib.sh
    . "$actions_dir/lib.sh"

    validate_wireguard

    wg_subnet="$(jq -r .subnet_cidr "$terraform_state_dir/config.tfvars.json")"
    wg_subnet_v6="$(jq -r .subnet_v6_cidr "$terraform_state_dir/config.tfvars.json")"
    # the grep is there to ignore any routes going via the interface we're going to
    # take down later either way
    wg_existing_route="$(ip route show to "$wg_subnet" 2>/dev/null | grep -v "dev $wg_interface" || true)"
    wg_existing_v6_route="$(ip -6 route show to "$wg_subnet_v6" 2>/dev/null | grep -v "dev $wg_interface" || true)"
    if { [ -n "$wg_existing_route" ] || [ -n "$wg_existing_v6_route" ]; } \
            && [ -z "${MANAGED_K8S_IGNORE_WIREGUARD_ROUTE:-}" ]; then
        if [ -n "$wg_existing_route" ]; then
            errorf 'route to wireguard network %s exists already: %s' "$wg_subnet" "$wg_existing_route" >&2
        fi
        if [ -n "$wg_existing_v6_route" ]; then
            errorf 'route to wireguard network %s exists already: %s' "$wg_subnet_v6" "$wg_existing_v6_route" >&2
        fi
        hintf 'disable the responsible interface(s)' >&2
        # shellcheck disable=SC2016
        hintf '(or set $MANAGED_K8S_IGNORE_WIREGUARD_ROUTE if you know what you'"'"'re doing)' >&2
        exit 2
    fi

    ipam_path="$cluster_repository/config/wireguard_ipam.toml"
    if python3 -c "import toml, sys; sys.exit(any(user['ident'] == '$wg_user' for user in toml.load('$ipam_path')['wg_users']))" ; then
        warningf 'failed to find wireguard user %s in trampoline configuration' "$wg_user" >&2
    fi

    #set up wireguard
    if [ -z ${wg_private_key+x} ]; then
        wg_private_key=$(cat "$wg_private_key_file")
    fi
    # Creating the conf file with a dummy key. The actual private key is going to be injected via `wg set`
    sed "s#REPLACEME#$(wg genkey)#" "$ansible_wg_template" > "$wg_conf"
    if ip link show "$wg_interface" 2>/dev/null >/dev/null; then
        if [ "$(id -u)" = '0' ]; then
            run ip link delete "$wg_interface" || true
        else
            run sudo ip link delete "$wg_interface" || true
        fi
    fi
    run wg-quick up "$wg_conf"
    rm "$wg_conf"
    if [ "$(id -u)" = '0' ]; then
        wg set "$wg_conf_name" private-key /dev/stdin <<< "$wg_private_key"
    else
        sudo wg set "$wg_conf_name" private-key /dev/stdin <<< "$wg_private_key"
    fi
    if [[ -v wg_mtu ]]; then
        if [ "$(id -u)" = '0' ]; then
	    ip l set mtu "$wg_mtu" dev "$wg_conf_name"
        else
            sudo ip l set mtu "$wg_mtu" dev "$wg_conf_name"
        fi
    fi
fi
