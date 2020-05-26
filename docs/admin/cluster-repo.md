# Cluster Repository

The cluster repository is a git repository. It holds all information which
define the (intended) state of a cluster. This information consists of:

- The version of the LCM code to deploy the cluster
- The version of the WireGuard user information
- State of Terraform
- State of the WireGuard IP address management (IPAM)
- Secrets and credentials obtained while deploying the cluster
- A configuration file which defines the platform layout and other properties
  of the cluster

## Repository layout

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


## Creating a new cluster repository

### Empty git repository

To start out with a cluster, you need an (empty) git repository which will
serve as your cluster repository:

```console
$ git init my-test-cluster
$ cd my-test-cluster
```

### Initialise cluster repository

To create the initial bare-minimum directory structure, a script is provided
in the `managed-k8s` project. You have two options to make use of that script:

1. Clone `managed-k8s` to a different location
2. Add `managed-k8s` as a submodule manually and use the script from there

We will use the first option in this guide, because it is well-supported.

Clone the `managed-k8s` repository to a location **outside** of your cluster
repository:

```console
$ pushd "$somewhere_else"
$ git clone git@gitlab.cloudandheat.com:lcm/managed-k8s
$ popd
```

Now you can run ``init.sh`` to bootstrap your cluster repository. Back in your
cluster repository directory, you now call the `init.sh` script from the
`managed-k8s` repositor you just cloned:

```console
$ "$somewhere_else/actions/init.sh"
```

The `init.sh` script will:

- Add all necessary submodules
- Copy a config.toml template if no config exists in the cluster repository yet
- Update the .gitignore to current standards


## Using the cluster repository

The `managed-k8s` submodule provides the following actions to work with the
cluster repository. All paths are relative to the cluster repository.

The scripts extensively rely on environment variables. See below for a
description of which environment variables exist and what they do.

- `managed-k8s/actions/apply.sh`: Runs terraform, stage2, stage3 and test in
  that order.

  See below for the individual steps.

- `managed-k8s/actions/apply-terraform.sh`: Run terraform

  This creates/updates the cluster platform infrastructure as defined by the
  configuration and the code in `managed-k8s`. It also updates the inventory
  files for ansible (`inventory/*/hosts`).

- `managed-k8s/actions/apply-stage2.sh`: Run ansible on the gateway nodes

  This installs the gateway nodes, including rolling out all users, setting
  up the basic infrastructure for C&H LBaaS and configuring wireguard.

- `managed-k8s/actions/apply-stage3.sh`: Run ansible on all nodes

  This installs the Kubernetes worker and master nodes, including rolling out
  all users, installing Kubernetes itself, deploying Rook, Prometheus etc.,
  and configuring C&H LBaaS (also on the gateways) if it is enabled.

  Also runs `managed-k8s/actions/wg-up.sh` (see below).

- `managed-k8s/actions/test.sh`: Run cluster tests

  This runs the cluster test suite. It ensures basic functionality:

  - Starting a pod & service
  - Cinder volume block storage
  - Rook ceph block storage (if enabled)
  - Rook ceph shared filesystem storage (if enabled)
  - C&H LBaaS (if enabled)
  - Pod security policies (if enabled)
  - Network policies (if enabled)
  - Monitoring (if enabled)

  Also runs `managed-k8s/actions/wg-up.sh` (see below).

- `managed-k8s/actions/wg-up.sh`: Bring up the WireGuard VPN to the cluster.

  It tries to be smart about not doing anything stupid and ensuring that you’re
  really connected to the correct cluster.

- `managed-k8s/actions/destroy.sh`: Destroy the entire cluster and all of its
  data.

  This is, obviously, destructive. Don’t run light-heartedly.

### Environment variables

The cluster management action scripts rely extensively on environment variables
to interact with the cluster. A full overview of the variables is provided
below.

**Tip:** It is recommended to use a local (uncommitted)
[direnv `.envrc`](https://direnv.net/) to have your shell automatically set the
required variables.

**Hint:** This LCM repository contains
[a template file](../../jenkins/envrc.template.sh) you can use to bootstrap
your own .envrc file.

- `wg_conf_name` (used by `wg-up.sh`): The name of the WireGuard interface to
  create. Interface name length is restricted to 15 bytes and should start
  with `wg`. Examples: `wg0`, `wg-k8s-dev`.

- `wg_private_key_file` (used by `wg-up.sh`): Path to your WireGuard private
  key file. This is not copied to any remote machine, but needed to generate
  the local configuration locally and to bring the VPN tunnel up.

- `wg_user` (used by `wg-up.sh`): Your WireGuard user name as per the
  [`wg_user` repository](https://gitlab.cloudandheat.com/lcm/wg_user).

- `TF_VAR_keypair` (used by `apply-terraform.sh`): The keypair name in
  OpenStack to use for creating new instances. Does not affect instances which
  have already been created.

- `MANAGED_K8S_SSH_USER` (used by `apply-stage2.sh`, `apply-stage3.sh`,
  and `test.sh`): The SSH user to use to log into the machines.

  By default, the ansible automation is written so that it’ll auto-detect one of
  the default SSH users (centos, debian, ubuntu) to connect to the machines.
  This only works if the machines were created with a keypair of which you hold
  the private key (see `TF_VAR_keypair`).

  The LCM will roll out all relevant users from the
  [ch-users-databag](https://gitlab.cloudandheat.com/configs/ch-users-databag/)
  via
  [ch-role-users](https://gitlab.cloudandheat.com/operations/ansible-roles/ch-role-users),
  so that you can log in using your normal login. To tell the LCM which user
  name that is, you have to set this environment variable.

- `OS_AUTH_URL`, `OS_IDENTITY_API_VERSION`, `OS_INTERFACE`, `OS_PASSWORD`,
  `OS_PROJECT_DOMAIN_ID`, `OS_PROJECT_NAME`, `OS_REGION_NAME`, `OS_USERNAME`,
  `OS_USER_DOMAIN_NAME` (used by `apply-terraform.sh`, `apply-stage3.sh`, and
  `destroy.sh`): OpenStack credentials.

  **Warning:** These credentials are copied into the cluster. Do NOT use your
  own user password here, but use the login of the dedicated OpenStack user of
  the cluster you are managing.

  **Warning:** Only use this exact set of variables. Using other, semantically
  similar variables (such as `OS_PROJECT_DOMAIN_NAME` instead of
  `OS_PROJECT_DOMAIN_ID`) is not supported and will lead to a broken cluster;
  the configuration files inside the cluster are generated solely based on the
  variables listed above.

- `MANAGED_K8S_COLOR_OUTPUT` (used by all scripts): Boolean value which either
  force enables or force disables coloured output of the scripts.

  By default, the scripts check whether they are running inside a tty. If they
  are, they will use coloured output. This environment variable can be set to
  override the auto-detection.

#### Behaviour-altering variables

The variables in this section should not be set during normal operation. They
disable safety checks or give consent to potentially dangerous operations.

* `MANAGED_K8S_RELEASE_THE_KRAKEN` (used by all scripts): Boolean value which
  defaults to false. If set to `true`, this allows the LCM to perform disruptive
  actions. See the [documentation on Disruption actions](../code/index.md) for
  details.

  By default, ansible and terraform will avoid to perform any actions which
  could cause a loss of data or loss of availability to the customer. This comes
  at the cost of not performing certain operations or refusing to continue at
  some places.

* `MANAGED_K8S_NUKE_FROM_ORBIT` (used by `destroy.sh`): Boolean value which
  defaults to false. If set to `true`, it will delete all Thanos monitoring
  data from the object store before destruction.

  **Note:** The destruction of the cluster will fail if Thanos monitoring data
  is still present in the object store. The reason for that is that terraform
  is not configured to delete the data by default. The reason for that, in turn,
  is that we want the operator to be aware that possibly contract-relevant
  monitoring data needs to be explicitly saved before destroying the cluster.

* `MANAGED_K8S_IGNORE_WIREGUARD_ROUTE` (used by `wg-up.sh`): By default,
  `wg-up.sh` will check if an explicit route for the cluster network exists
  on your machine. If such a route exists and does not belong to the wireguard
  interface set via `wg_conf_name`, the script will abort with an error.

  The reason for that is that it is unlikely that you’ll be able to connect
  to the cluster this way and that weird stuff is bound to happen.

  If you know what you’re doing (I certainly don’t), you can set
  `MANAGED_K8S_IGNORE_WIREGUARD_ROUTE` to any non-empty value to override this
  check.
