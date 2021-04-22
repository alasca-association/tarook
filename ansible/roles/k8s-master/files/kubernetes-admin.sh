# shellcheck shell=sh
if [ -r /etc/kubernetes/admin.conf ] && [ "${KUBECONFIG:-}" = '' ]; then
        export KUBECONFIG=/etc/kubernetes/admin.conf
fi
