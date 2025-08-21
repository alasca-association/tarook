#!/usr/bin/env bash

rc="$(mktemp)"
echo 0 > "$rc"
find . -name '*.gpg' -print0 | while IFS= read -r -d '' keyfile; do
    echo "INFO: Checking key $keyfile"
    if (file --mime-type --brief "$keyfile" | grep --quiet '^application/pgp-keys$'); then
        echo "INFO: Found PGP public key"
        keys="$(gpg --show-keys --with-colon --fixed-list-mode "$keyfile")"
    elif (file --brief "$keyfile" | grep --quiet "^GPG keybox database"); then
        echo "INFO: Found keybox database"
        gpg_temp_dir=$(mktemp -d)
        keys="$(gpg --homedir "$gpg_temp_dir" --no-default-keyring --keyring "$keyfile" \
                    --list-keys --with-colon --fixed-list-mode)"
        rm -rf "$gpg_temp_dir"
    else
        echo "ERROR: Unknown file type"
        echo 1 > "$rc"
        continue
    fi

    expiry_dates="$(echo "$keys" | grep -E '^pub' | cut -d':' -f 7)"

    echo "$expiry_dates" | while IFS= read -r expiry_date; do
        if [[ -z "$expiry_date" ]]; then
        echo "INFO: $keyfile doesn't have an expiry date"
        continue
        fi
        echo "INFO: Key expires on $(date --date=@"$expiry_date" '+%Y-%m-%d')"
        if [[ $expiry_date -le $(date -d "+90 days" +%s) ]]; then
        echo "ERROR: $keyfile expires in less than 90 days"
        echo 1 > "$rc"
        fi
    done
done
exit "$(<"$rc")"
