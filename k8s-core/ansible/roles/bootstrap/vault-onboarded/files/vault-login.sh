#!/bin/bash
set -euo pipefail
umask 0077
vault_dir=/etc/vault-client
for delay in 1 2 4 8 16 0; do
    role_id="$(cat "$vault_dir/role-id")"
    secret_id="$(cat "$vault_dir/secret-id")"
    jq -R --slurp '(. / "\n") | {"role_id": .[0], "secret_id": .[1]}' <<<"$role_id"$'\n'"$secret_id" | vault write -field=token "auth/yaook/nodes/login" - && exit 0
    sleep $delay
done
printf 'failed to log into vault!\n' >&2
exit 2
