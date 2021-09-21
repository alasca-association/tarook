# shellcheck shell=sh
if [ -r /etc/kubernetes/admin.conf ] && [ "x${KUBECONFIG:-}" = 'x' ]; then
        export KUBECONFIG=/etc/kubernetes/admin.conf
fi
