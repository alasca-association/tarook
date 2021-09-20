# Layout

The following schema shows all non-generated files. A local checkout will most
certainly have more files than these.

```
cluster_repo
├── config/
│   ├── config.toml  # Cluster configuration
│   └── wireguard_ipam.toml  # WireGuard IPAM
├── terraform/
│   ├── .terraform/
│   │   └── plugins/
│   │       └── linux_amd64/
│   │           └── lock.json  # Terraform plugin version lock
│   ├── terraform.tfstate  # Terraform state
│   └── terraform.tfstate.backup  # Terraform state backup
├── inventory/
│   └── .etc/  # Credentials / Secrets
├── managed-k8s/  # Submodule with the LCM code
└── wg_user/  # Submodule with the WireGuard user information
```

Detailed explanation:

- `config/config.toml` holds the configuration variables of the cluster. A
  template for this file can be found in
  [jenkins/config.template.toml](/jenkins/config.template.toml).

  Note that the `init.sh` action (see below) will bootstrap your configuration
  from that template.

- `terraform` is a state-only directory for Terraform. You should not need to
  manually operate in that directory at all. See below for `apply-terraform.sh`
  to apply only Terraform-managed changes.

- `inventory/.etc/` holds credentials generated during creation of the cluster.
  In the future, this will be moved to a secure credentials store (see #52).

- `managed-k8s` is a git submodule which refers to this (the `managed-k8s`)
  repository. By using a submodule, we get a pinning to an exact commit and
  hold the hash of that commit inside the cluster repository. This allows us
  to reproducibly roll out the cluster with the same state without changes
  again, even if the branch of `managed-k8s` has advanced in the meantime.

- `wg_user` is a git submodule which refers to
  [the `wg_user` repository](https://gitlab.cloudandheat.com/lcm/wg_user). It
  holds the WireGuard public keys of all our (CLOUD&HEAT) users.
