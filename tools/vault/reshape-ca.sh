#!/bin/bash
set -euo pipefail

cafile="$1"
cakey="$2"
workdir="$(mktemp -d --tmpdir reshape-ca.XXXXXXXXXXXX)"
outfile="$3"

if [ -e "$outfile" ]; then
    echo "$outfile exists, refusing to overwrite" >&2
    exit 2
fi

function cleanup() {
    rm -rf -- "$workdir"
}

trap cleanup EXIT

csrfile="$workdir/csr"
config="$workdir/openssl.cnf"

cat > "$config" <<EOF
[ ca_extensions ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always, issuer
basicConstraints       = critical, CA:true
keyUsage               = keyCertSign, cRLSign
EOF

uuidhex="$(uuidgen --random | tr -d '-')"
date="$(date '+%Y%m%d')"
serial="$(printf '0x%08x%s' "$date" "$uuidhex")"

old_enddate_unix="$(date -d "$(openssl x509 -noout -enddate -in "$cafile" | cut -d= -f2-)" +%s)"
now_unix="$(date +%s)"
days=$(( (old_enddate_unix - now_unix) / 86400 ))

openssl x509 -x509toreq -in "$cafile" -signkey "$cakey" -out "$csrfile"
openssl x509 -req -in "$csrfile" -signkey "$cakey" -out "$outfile" -set_serial "$serial" -extfile "$config" -extensions ca_extensions -days "$days"
