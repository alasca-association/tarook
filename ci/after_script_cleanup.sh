#!/usr/bin/env bash

set -euo pipefail

# No idea why I have to configure the wg tunnel again. Is the after-script executed in a different container?
# We're accepting a failure here because I'm too lazy to check whether wireguard was already configured. Since
# k8s-dump.sh can also fail gracefully -> no harm, no foul.
export wg_conf_name="wg0"
tarook wireguard up || true

if [ -f "$PWD/etc/admin.conf" ]; then
    export KUBECONFIG="$PWD/etc/admin.conf"
    ./managed-k8s/tools/dump-k8s.sh podlogs --all-namespaces '' pod deployment pvc statefulset daemonset configmap secrets || true
fi

# Use `openrc.sh` if present on the filesystem of the GitLab Runner
# else it is expected that the openrc env vars are configured as CI/CD variables
# The openrc file is not available in the shellcheck image
# shellcheck disable=SC1091
if [ -f /root/openrc.sh ] ; then source /root/openrc.sh; fi
rm state/terraform/prevent_disruption.lock
MANAGED_K8S_RELEASE_THE_KRAKEN=true MANAGED_K8S_DISRUPT_THE_HARBOUR=true MANAGED_K8S_NUKE_FROM_ORBIT=true tarook destroy
