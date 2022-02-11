# Environment Variable Reference

The cluster management action scripts rely extensively on environment variables
to interact with the cluster. A full overview of the variables is provided
below. It is strongly recommended to read the whole document before starting
to [initialize a cluster repository](./initialization.md) for the first time.

> ***Tip*:** It is recommended to use a local (uncommitted)
> [direnv `.envrc`](https://direnv.net/) to have your shell automatically set the
> required variables.

> ***Hint*:** This repository contains
> [a template file](#template) which you can use. However, you **must**
> adjust some of its values.

## Minimal Required Changes

When initializing your env vars from the template, you'll need to minimally (sic!) adjust the following ones:

* If you're deploying on top of OpenStack:
  * [OpenStack Credentials](#openstack-credentials)
  * SSH Configuration
    * `TF_VAR_keypair`
  * VPN Configuration
    * `wg_private_key_file`
    * `wg_user`
* If you're deploying on top of Bare Metal:
  * Disable `TF_USAGE`
  * Disable `WG_USAGE`

Details about these can be found below.

## General

| Environment Variable       | Default | Description                                                                                                                                                                                                                                                                      |
| :------------------------- | :------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MANAGED_K8S_COLOR_OUTPUT` |         | Boolean value which either force enables or force disables coloured output of the scripts. By default, the scripts check whether they are running inside a tty. If they are, they will use coloured output. This environment variable can be set to override the auto-detection. |
## OpenStack credentials

* These **MUST** be set if you want to deploy on OpenStack.
* Necessary variables:`OS_AUTH_URL`, `OS_IDENTITY_API_VERSION`, `OS_INTERFACE`, `OS_PASSWORD`,
  `OS_PROJECT_DOMAIN_ID`, `OS_PROJECT_NAME`, `OS_REGION_NAME`, `OS_USERNAME`,
  `OS_USER_DOMAIN_NAME`
* These variables are used by Terraform to create, maintain and destroy the underlying
  harbour infrastructure layer. They are also needed by the [Cloud Controller Manager](https://kubernetes.io/docs/concepts/architecture/cloud-controller/)
  when applying the k8s-base layer.

> ***Warning:*** These credentials are copied into the cluster. You SHOULD use
> a dedicated OpenStack project for your cluster.

> ***Warning:*** Only use this exact set of variables. Using other, semantically
> similar variables (such as `OS_PROJECT_DOMAIN_NAME` instead of
> `OS_PROJECT_DOMAIN_ID`) is not supported and will lead to a broken cluster;
> the configuration files inside the cluster are generated solely based on the
> variables listed above.

## External resources

| Environment Variable                 | Default                                                              | Description                                                                                                                                    |
| :----------------------------------- | :------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------- |
| `MANAGED_K8S_GIT`                    | `gitlab.com:yaook/k8s`                                               | This git URL is used by `init.sh` to bootstrap the LCM (`yaook/k8s`) repository. Can be used to override the repository to use another mirror. |
| `MANAGED_K8S_WG_USER_GIT`            | `gitlab.cloudandheat.com:lcm/wg_user`                                | Git URL to a repository with wireguard keys to provision. Can be enabled by setting `WG_COMPANY_USERS` (see below).                            |
| `MANAGED_K8S_PASSWORDSTORE_USER_GIT` | `gitlab.cloudandheat.com:lcm/mk8s-passwordstore-users`               | Git URL to a repository with users to grant access to cluster secrets. Can be enabled by setting `PASS_COMPANY_USERS` (see below).             |
| `MANAGED_CH_ROLE_USER_GIT`           | `gitlab.cloudandheat.com:operations/ansible-roles/ch-role-users.git` | URL to the ch-role-users role submodule. Can be enabled by setting `SSH_COMPANY_USERS` (see below).                                            |

## Secret Management

| Environment Variable | Default | Description                                                                                                                                                                   |
| :------------------- | :------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PASS_COMPANY_USERS` | `false` | If set to true, `init.sh` will clone the repository `MANAGED_K8S_PASSWORDSTORE_USER_GIT`. The users in that repository will be granted access to the pass-based secret store. |

## VPN Configuration

| Environment Variable  | Default               | Description                                                                                                                                                                                                                                                                                                                                      |
| :-------------------- | :-------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `wg_conf_name`        | `"wg0"`               | This variable defines the name of the WireGuard interface to create. Interface name length is restricted to 15 bytes and should start with `wg`. Examples: `wg0`, `wg-k8s-dev`. This variable is used by the [`wg-up.sh`-script](../operation/actions-references.md#wg-upsh).                                                                    |
| `wg_private_key_file` | `"$(pwd)/../privkey"` | Path to your WireGuard private key file. This is not copied to any remote machine, but needed to generate the local configuration locally and to bring the VPN tunnel up. You **MUST** adjust this variable. This variable is used by the [`wg-up.sh`-script](../operation/actions-references.md#wg-upsh).                                       |
| `wg_user`             | `"firstnamelastname"` | Your WireGuard user name as defined in the [wireguard configuration](./cluster-configuration.md#wireguard-configuration) (or, if enabled, [`wg_user` repository](https://gitlab.cloudandheat.com/lcm/wg_user)). You **MUST** adjust this variable. This variable is used by the [`wg-up.sh`-script](../operation/actions-references.md#wg-upsh). |
| `WG_COMPANY_USERS`    | `false`               | If set to true, `init.sh` will clone the repository `MANAGED_K8S_WG_USER_GIT`. The inventory updater will then configure the wireguard users from that repository.                                                                                                                                                                               |

## SSH Configuration

| Environment Variable   | Default                                | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| :--------------------- | :------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `TF_VAR_keypair`       | `"firstnamelastname-hostname-gendate"` | Defines the keypair name (in OpenStack) which will be used during the creation of new instances. Does not affect instances which have already been created. You **MUST** adjust this variable if you want to deploy on top of OpenStack. This variable is used by the [`apply-terraform.sh`](./../operation/actions-references.md#apply-terraformsh).                                                                                                                                                                                                                                                                                                                                                                                           |
| `MANAGED_K8S_SSH_USER` |                                        | The SSH user to use to log into the machines. This variable *SHOULD* be set. By default, the Ansible automation is written such that it’ll auto-detect one of the default SSH users (`centos`, `debian`, `ubuntu`) to connect to the machines. This only works if the machines were created with a keypair of which you hold the private key (see `TF_VAR_keypair`). If the LCM is configured to roll out all relevant users from the [ch-users-databag](https://gitlab.cloudandheat.com/configs/ch-users-databag/) via [ch-role-users](https://gitlab.cloudandheat.com/operations/ansible-roles/ch-role-users) (see `SSH_COMPANY_USERS`), you'll need to ensure that this the correct user is used when trying to bring up the SSH connection. |
| `SSH_COMPANY_USERS`    | `false`                                | If set to true, `init.sh` will clone the repository `MANAGED_CH_ROLE_USER_GIT`. The inventory updater will then configure your inventory such that the `ch-role-users` role is executed in stage2 and stage3.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |

## Behavior-altering variables

The variables in this section should not be set during normal operation. They
disable safety checks or give consent to potentially dangerous operations.

| Environment Variable                 | Default | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| :----------------------------------- | :------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MANAGED_K8S_RELEASE_THE_KRAKEN`     | `false` | Boolean value which defaults to false. If set to `true`, this allows the LCM to perform disruptive actions. See the documentation on Disruption actions for details. <br />By default, ansible and terraform will avoid to perform any actions which could cause a loss of data or loss of availability to the customer. This comes at the cost of not performing certain operations or refusing to continue at some places.                                                                             |
| `MANAGED_K8S_NUKE_FROM_ORBIT`        | `false` | Boolean value which defaults to false. If set to `true`, it will delete all Thanos monitoring data from the object store before destruction.                                                                                                                                                                                                                                                                                                                                                             |
| `MANAGED_K8S_IGNORE_WIREGUARD_ROUTE` |         | By default, `wg-up.sh` will check if an explicit route for the cluster network exists on your machine. If such a route exists and does not belong to the wireguard interface set via `wg_conf_name`, the script will abort with an error. </br> The reason for that is that it is unlikely that you’ll be able to connect to the cluster this way and that weird stuff is bound to happen. If you know what you’re doing (I certainly don’t), you can set to any non-empty value to override this check. |
| `TF_USAGE`                           | `true`  | Allows to disable execution of the terraform stage by setting it to false. This is also taken into account by the inventory helper. Intended use case are bare-metal or otherwise pre-provisioned setups.                                                                                                                                                                                                                                                                                                |
| `AFLAGS`                             |         | This allows to pass additional flags to Ansible. The variable is interpolated into the ansible call without further quoting, so it can be used to do all kinds of fun stuff. A primary use is to force diff output or only execute some tags: `AFLAGS="--diff -t some-tag"`.                                                                                                                                                                                                                             |
| `K8S_CUSTOM_STAGE_USAGE`             | `false` | If set to true, `init.sh` will create a base skeleton for the [customization layer](../design/abstraction-layers.md#customization) in your cluster repository. Also the [`apply.sh`-script](./../operation/actions-references.md#applysh) will now include the appliance of this stage.                                                                                                                                                                                                                  |

>***Note:*** The destruction of the cluster will fail if Thanos monitoring data
>is still present in the object store. The reason for that is that terraform
>is not configured to delete the data by default. The reason for that, in turn,
>is that we want the operator to be aware that possibly contract-relevant
>monitoring data needs to be explicitly saved before destroying the cluster.

>***Note:*** You should not use the `AFLAGS`-mechanism to pass sustained variables
> to Ansible. These variables should be set in your Ansible configuration file or hosts file(s).

>***Note:*** If you have already initialized you cluster repository, you'll need to rerun the [`init.sh`-script](./../operation/actions-references.md#initsh)
> after enabling the Customization layer.
## Template

The template file is located at `templates/envrc.template.sh`.

```bash
{{#include ../templates/envrc.template.sh}}
```
