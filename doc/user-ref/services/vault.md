# HashiCorp Vault

The `vault_v1` role deploys a HashiCorp Vault instance in the Kubernetes
cluster. This is not to be confused with (upcoming) support for using HashiCorp
Vault as a backend for storing LCM secrets.

For more details about the software, check out the
[HashiCorp Vault](https://www.vaultproject.io/) website. The deployment happens
via the [Vault Helm Chart](https://github.com/hashicorp/vault-helm/).

***Note:*** The Vault integration is not ready for productive use yet, as it
does not yet support high availability or backups. In addition, the unseal keys
will be **printed in plaintext** in the ansible output on the first deployment
and **must be stored safely and manually**, otherwise they're lost forever.

## Vault Configuraton

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: ksl_vault_configuration"
end-before: "# ANCHOR_END: ksl_vault_configuration"
language: toml
---
```
