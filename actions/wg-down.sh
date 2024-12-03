#!/usr/bin/env bash
set -euo pipefail

actions_dir="$(dirname "$0")"
# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"
load_conf_vars

validate_wireguard

if ip link show "$wg_interface" 2>/dev/null >/dev/null; then
    if [ "$(id -u)" = '0' ]; then
        run ip link delete "$wg_interface" || true
    else
        run sudo ip link delete "$wg_interface" || true
    fi
else
    hintf "Interface ${wg_interface} not found."
fi
