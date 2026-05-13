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
lines = content.splitlines()
blocks_as_lines = [block.strip("\n").splitlines() for block in blocks_to_remove]

filtered_lines = []
idx = 0
while idx < len(lines):
    matched_block = False
    for block in blocks_as_lines:
        if lines[idx:idx + len(block)] == block:
            idx += len(block)
            matched_block = True
            break

    if matched_block:
        continue

    if lines[idx].strip() not in lines_to_remove:
        filtered_lines.append(lines[idx])

    idx += 1

new_content = "\n".join(filtered_lines).rstrip()
if new_content:
    new_content += "\n"

envrc.write_text(new_content)