# Environment Variable Reference

<!-- TODO: needs updating with current LCM -->

The cluster management action scripts rely extensively on environment variables
to interact with the cluster. A full overview of the variables is provided
below.

**Tip:** It is recommended to use a local (uncommitted)
[direnv `.envrc`](https://direnv.net/) to have your shell automatically set the
required variables.

**Hint:** This LCM repository contains
[a template file](../../jenkins/envrc.template.sh) you can use to bootstrap
your own .envrc file.

## General

- `MANAGED_K8S_SSH_USER`: The SSH user to use to log into the machines.

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

## External resources

- `MANAGED_K8S_GIT`: This URL is used by `init.sh` to bootstrap the cluster
  repository. Can be used to override the repository to use another mirror.

- `MANAGED_K8S_WG_USER_GIT`: Git URL to a repository with wireguard keys to
  provision. See `WG_COMPANY_USERS` below.

- `MANAGED_K8S_PASSWORDSTORE_USER_GIT`: Git URL to a repository with users to
  grant access to cluster secrets. See `PASS_COMPANY_USERS` below.

- `MANAGED_CH_ROLE_USER_GIT`: URL to the ch-role-users role submodule.

## Secret management

- `PASS_COMPANY_USERS` (boolean, default: true): If set to true, `init.sh` will
  clone the repository `MANAGED_K8S_PASSWORDSTORE_USER_GIT`. The users in that
  repository will be granted access to the pass-based secret store.

- `WG_COMPANY_USERS` (boolean, default: true): If set to true, `init.sh` will
  clone the repository `MANAGED_K8S_WG_USER_GIT`. The inventory helper will
  then configure the wireguard users from that repository.

## VPN Configuration

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

## Behaviour-altering variables

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

* `AFLAGS`: This allows to pass additional flags to ansible. The variable is
  interpolated into the ansible call without further quoting, so it can be used
  to do all kinds of fun stuff.

  A primary use is to force diff output or only execute some tags:

  ```bash
  AFLAGS="--diff -t some-tag" ./managed-k8s/actions/apply-stage3.sh
  ```

* `TF_USAGE` (default: true): Allows to disable execution of the terraform
  stage by setting it to false.

  This is also taken into account by the inventory helper. Intended use case
  are bare-metal or otherwise pre-provisioned setups.
