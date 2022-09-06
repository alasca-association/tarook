#!/usr/bin/env bash
set -euo pipefail

# Create vault certificate folder
mkdir -p tls/ca
cd tls/

# Create openssl config file
# shellcheck disable=SC2154
cat >"openssl.cnf" <<EOF
[req]
default_bits = 4096
encrypt_key  = yes
default_md   = sha256
prompt       = no
utf8         = yes
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
O  = YAOOK
CN = VAULT
[v3_req]
basicConstraints     = CA:FALSE
subjectKeyIdentifier = hash
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = serverAuth
subjectAltName       = @alt_names
[alt_names]
IP.1  = 127.0.0.1
DNS.1 = localhost
DNS.2 = yaook-vault
DNS.3 = $vault_container_name
EOF

# Create CA certificate and key
openssl req \
    -new \
    -newkey rsa:4096 \
    -days 1024 \
    -nodes \
    -x509 \
    -subj "/O=VAULT CA" \
    -keyout "./ca/vaultca.key" \
    -out "./ca/vaultca.crt"

# Create certificate key and set read permission for Vault container
openssl genrsa -out "vault.key" 4096
chmod g+r vault.key

# Create certificate request file from OpenSSL config
openssl req \
    -new -key "vault.key" \
    -out "vault.csr" \
    -config "openssl.cnf"

# Create server certifiacte
openssl x509 \
    -req \
    -days 1024 \
    -in "vault.csr" \
    -CA "./ca/vaultca.crt" \
    -CAkey "./ca/vaultca.key" \
    -CAcreateserial \
    -extensions v3_req \
    -extfile "openssl.cnf" \
    -out "vault.crt"

# Create certificate chain
cat vault.crt >"vaultchain.crt"
cat "./ca/vaultca.crt" >>"vaultchain.crt"
