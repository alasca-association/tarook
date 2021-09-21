#!/bin/bash
set -euo pipefail

if [ "x${CI:-}" == 'x' ]; then
    # You do not want to run this against your production cluster.
    echo 'This script can only be run in a CI context for safety reasons.' >&2
    exit 2
fi

function check_reachable() {
    # shellcheck disable=SC2207
    IFS=$'\n' ip_addresses=($(jq -r '(.resources | map(select(.type == "openstack_compute_floatingip_associate_v2" and .name == "gateway")))[].instances[].attributes.floating_ip' terraform/terraform.tfstate))
    all_good=true
    for address in "${ip_addresses[@]}"; do
        printf 'Waiting for %q to respond to SSH ..' "$address"
        ok=false
        # shellcheck disable=SC2034
        for i in $(seq 1 12); do
            printf '.'
            if timeout 5 nc -z "$address" 22; then
                ok=true
                break
            fi
            sleep 1
        done
        if [ "$ok" = 'true' ]; then
            printf ' ok!\n'
        else
            printf '\ntimed out while waiting for connectivity!\n'
            all_good=false
            break
        fi
    done

    if [ "$all_good" == 'true' ]; then
        return 0
    else
        return 127
    fi
}


if ! check_reachable; then
    echo 'Not all SSH services became reachable'
    echo 'But don'"'"'t worry! This is a known issue, and I'"'"'m going to'
    echo 'work around it for you.'

    MANAGED_K8S_RELEASE_THE_KRAKEN=true MANAGED_K8S_NUKE_FROM_ORBIT=true ./managed-k8s/actions/destroy.sh

    echo 'So now that I destroyed EVERYTHING, I'"'"'m going to give OpenStack'
    echo 'a bit of time to come to terms with things. Ten minutes, to be exact.'

    sleep 10m

    echo 'Sleepytime over, let'"'"'s try again!'
    ./managed-k8s/actions/apply-terraform.sh

    if ! check_reachable; then
        echo 'Bummers. That did not help. Sorry.'
        exit 127
    fi
fi
