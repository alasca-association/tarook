{
  "storage": {
    "file": {
      "path": "/vault/data"
    }
  },
  "listener": {
    "tcp": {
      "address": "0.0.0.0:8200",
      "tls_disable": "false",
      "tls_cert_file": "/vault/tls/vaultchain.crt",
      "tls_key_file": "/vault/tls/vault.key",
      "tls_require_and_verify_client_cert": "false",
      "tls_disable_client_certs": "true"
    }
  },
  "disable_mlock": "true",
  "api_addr": "http://0.0.0.0:8200",
  "ui": "true",
  "log_level": "info"
}
