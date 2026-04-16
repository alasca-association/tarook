#!/usr/bin/env bash
set -euo pipefail

actions_dir="$(dirname "$0")"

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

# Available arguments
declare -a arguments=("--with-kubernetes-networks" "--help")

# Ensure that the latest config is deployed to the inventory
"$actions_dir/update-inventory.sh" conf_vars

# print help message
function helpf() {
  action_name=${0##*/}
  printf "%s - Action Script to establish a Wireguard tunnel to the Cluster\n\n" "$action_name"
  printf "Usage: %s [--help|--with-kubernetes-networks]\n\n" "$action_name"
  printf "Flags:"
  printf "\n--help                        Print this help message"
  printf "\n--with-kubernetes-networks    Establish a tunnel to the Kubernetes Pod\n"
  printf "                              and Service network as well\n"
  printf "                              This can be persistently configured by setting\n"
  printf "                              'TAROOK_WG_TO_K8S_NETWORKS' to 'true'\n"
}

# Check for valid number of arguments (<=1)
arg_num=1
if [ "$#" -gt "$arg_num" ]; then
    errorf "ERROR: Expecting at most $arg_num argument(s), but $# were given"
    echo
    helpf
    exit 2
fi

# Verify supplied argument
if [ "$#" -eq $arg_num ]; then
    argument="$1"
    if [ "$argument" == "--help" ]; then
        helpf
        exit 0
    fi
    # Check if argument is valid
    # shellcheck disable=SC2068
    for i in ${arguments[@]}; do
        if [[ "$i" == "$argument" ]]; then
            valid_argument=true
        fi
    done
    if [ -z "${valid_argument:-}" ]; then
        errorf "$argument is not a valid argument\n" >&2
        helpf
        exit 2
    fi
    if [ "$argument" == "--with-kubernetes-networks" ]; then
        with_kubernetes_networks=true
    fi
fi

load_conf_vars

if [ "${wg_usage:?}" == "true" ]; then
    validate_wireguard

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

    ipam_path="$state_dir/wireguard/ipam.toml"
    if ! tomlq '(.wg_users[] | select(.ident=="'"${wg_user}"'")) // error("not-found")' "$ipam_path" &>/dev/null ; then
        warningf 'Failed to find configured wg_user "%s" in Wireguard IPAM state file (%s).' "$wg_user" "$ipam_path" >&2
        warningf '  Is the user configured as Wireguard peer?' >&2
        warningf '  See https://docs.tarook.cloud/devel/user/reference/environmental-variables.html#vpn-configuration' >&2
        warningf '  and https://docs.tarook.cloud/devel/user/reference/options/yk8s.wireguard.html#yk8s-wireguard-peers' >&2
    fi

    #set up wireguard
    if [[ -v wg_private_key_command ]]; then
        # shellcheck disable=SC2086
        wg_private_key=$(env --ignore-environment --split-string="$wg_private_key_command")
    elif [[ -v wg_private_key_file ]]; then
        warningf "\$wg_private_key_file is deprecated. Please use \$wg_private_key_command instead. See https://docs.tarook.cloud/devel/user/reference/environmental-variables.html#vpn-configuration"
        wg_private_key=$(cat "$wg_private_key_file")
    elif [[ -v wg_private_key ]]; then
        warningf "\$wg_private_key is deprecated. Please use \$wg_private_key_command instead. See https://docs.tarook.cloud/devel/user/reference/environmental-variables.html#vpn-configuration"
    fi
    # Creating the conf file with a dummy key. The actual private key is going to be injected via `wg set`
    sed "s#REPLACEME#$(wg genkey | sed 's/^.\{10\}/dummy+key+/')#" "$ansible_wg_template" > "$wg_conf"
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
else
    notef "You called this script although Wireguard is disabled."
    notef "It is assumed this happened by accident."
    notef "Failing gracefully."
    exit 1
fi
