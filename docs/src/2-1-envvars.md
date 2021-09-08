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
