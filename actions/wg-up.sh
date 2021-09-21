#!/bin/bash
set -euo pipefail
actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"

validate_wireguard

wg_subnet="$(jq -r .subnet_cidr "$terraform_state_dir/config.tfvars.json")"
# the grep is there to ignore any routes going via the interface we're going to
# take down later either way
wg_existing_route="$(ip route show to "$wg_subnet" | grep -v "dev $wg_interface" || true)"
if [ -n "$wg_existing_route" ] && [ -z "${MANAGED_K8S_IGNORE_WIREGUARD_ROUTE:-}" ]; then
    errorf 'route to wireguard network %s exists already: %s' "$wg_subnet" "$wg_existing_route" >&2
    hintf 'disable the responsible interface' >&2
    # shellcheck disable=SC2016
    hintf '(or set $MANAGED_K8S_IGNORE_WIREGUARD_ROUTE if you know what you'"'"'re doing)' >&2
    exit 2
fi

if [ -z "$(jq --arg user "$wg_user" -r '.ansible["02_trampoline"].group_vars.gateways.wg_peers[].ident | select(. == $ARGS.named.user)' "$cluster_repository/config/config.json")" ]; then
    warningf 'failed to find wireguard user %s in trampoline configuration' "$wg_user" >&2
    hintf 'since this is likely to break wireguard, it will lead to stage 3 failing with timeouts' >&2
fi

#set up wireguard
old_umask="$(umask)"
# prevent private key from leaking to the public
umask 0077
# TODO: invoking sed with the private key in the argument is meh, because that
# may be visible to other users
sed "s#REPLACEME#$(cat "$wg_private_key_file")#" "$ansible_wg_template" > "$wg_conf"
umask "$old_umask"
if ip link show "$wg_interface" 2>/dev/null >/dev/null; then
    if [ "$(id -u)" = '0' ]; then
        run ip link delete "$wg_interface" || true
    else
        run sudo ip link delete "$wg_interface" || true
    fi
fi
run wg-quick up "$wg_conf"
