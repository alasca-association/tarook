# Quick Start Guide

If you want to create a yk8s cluster on OpenStack, follow the following steps.
A bare-metal yk8s cluster requires further preparations.

These are minimal instructions on how to deploy a yk8s-cluster.
When nothing else is specified, the working directory is assumed to be the top level of the
[cluster repository](./../design/cluster-repository.md).

---

1. Initialize your personal yk8s-cluster by creating the prerequisites and following the steps mentioned in the [initialization documentation page](./../usage/initialization.md).

2. Review and adjust the `config/config.toml` to meet your needs. At a bare minimum you need to adjust the following things:
   
   * You need to add your gpg key to the [additional passwordstore users](#passwordstore-configuration).
     * Please do also ensure that your gpg keyring is up-to-date.
   * You need to add your (public) wireguard key to the [wireguard peer configuration](./../usage/cluster-configuration.md#wireguard-configuration).
   * You need to create a secret for the [ch-k8s-lbaas](./../managed-services/load-balancing/ch-k8s-lbaas.md#ch-k8-lbaas-configuraton) if your cluster runs on top of OpenStack.

3. Trigger the cluster creation by executing the [`apply.sh`](./actions-references.md#applysh) script.

4. Get yourself a hot beverage and joyfully watch as your yk8s cluster gets created and tested.

---

## Passwordstore Configuration

To ensure that secrets wil be encrypted for you, you need to add yourself to the passwordstore users.
To do so, adjust the following section in your `config/config.toml` by following the clues in the comments.

```toml
{{#include ../templates/config.template.toml:passwordstore_configuration}}
```

*Hint: You can list available keys via `gpg -K`.*

## FAQ - Frequently Asked Questions and Problems

### "I can't ssh to the host nodes"

Connecting to a local IP address of any cluster node requires first setting up the wireguard tunnel.
If it is not already up, you can set it up by running the [`wg-up.sh`-script](./actions-references.md#wg-upsh).

Also ensure that your key is in [a supported format](./../usage/initialization.md#pre-init-requisites).
You may need to explicitly specify which key Ansible shall use for connections by setting
`ansible_ssh_private_key_file` in your [Ansible configuration](./../usage/cluster-configuration.md#ansible-configuration)
or by setting it in the `AFLAGS` [environment variable](./../usage/environmental-variables.md#behavior-altering-variables).
Further information about Ansible connections can be found [here](https://docs.ansible.com/ansible/latest/user_guide/connection_details.html).

### "How can I delete my yk8s-Cluster?"

You can delete the yk8s-Cluster and all associated OpenStack resources by triggering
the [`destroy.sh`-script](./actions-references.md#destroysh).
**Warning**: This cannot be undone.
Note that the [configuration](./../usage/cluster-configuration.md) of the cluster is not reset.

```console
# Destroy the yk8s cluster and delete all OpenStack resources
$ MANAGED_K8S_RELEASE_THE_KRAKEN=true MANAGED_K8S_NUKE_FROM_ORBIT=true ./managed-k8s/actions/destroy.sh
```
