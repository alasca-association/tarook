#!/usr/bin/env python3

from pathlib import Path

lines_to_remove = [
    "# Optional: Useful to be able to interact with the cluster via kubectl.",
    'export KUBECONFIG="$(pwd)/etc/admin.conf"',
]

blocks_to_remove = [
    """
KUBECONFIG="$(pwd)/etc/admin.conf"
export KUBECONFIG
""",
    """
if [ -f "$KUBECONFIG" ] && ! yq -r '.users[0].user."client-certificate-data"' "$KUBECONFIG" | base64 -d | openssl x509 -checkend 186400 -noout >/dev/null; then
  echo "======="
  echo "WARNING: Your kubeconfig is expired or will expire within the next 24h. Please run ./managed-k8s/actions/k8s-login.sh to renew it"
  echo "======="
fi
""",  # noqa: 501
]

envrc = Path(".envrc")

content = envrc.read_text()
for block in blocks_to_remove:
    content = content.replace(block, "")

lines = content.splitlines(True)
lines = [l for l in lines if l.strip() not in lines_to_remove]  # noqa: E741


if lines and lines[-1].strip() == "":
    lines.pop()

envrc.write_text("".join(lines))
