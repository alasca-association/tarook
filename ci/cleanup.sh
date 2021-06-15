#!/bin/bash

set -euo pipefail

# No idea why I have to configure the wg tunnel again. Is the after-script executed in a different container?
export wg_conf_name="wg0"
./managed-k8s/actions/wg-up.sh

if [ -f "$PWD/inventory/.etc/admin.conf" ]; then
    export KUBECONFIG="$PWD/inventory/.etc/admin.conf"
    ./managed-k8s/tools/dump-k8s.sh podlogs --all-namespaces '' pod deployment pvc statefulset daemonset configmap secrets || true
fi

# The openrc file is not available in the shellcheck image
# shellcheck disable=SC1091
. /root/openrc.sh
MANAGED_K8S_RELEASE_THE_KRAKEN=true MANAGED_K8s_NUKE_FROM_ORBIT=true ./managed-k8s/actions/destroy.sh
