# Actions Reference

The `managed-k8s` submodule provides the following ready-to-use action scripts to work with the
cluster repository.
The scripts extensively rely on environment variables.
See the [Environment Variables Reference](./../usage/environmental-variables.md) for details.

## `init.sh`

The `init.sh`-script is used for the [Cluster Repository Initialization](./../usage/initialization.md).
Before executing this script you **must** have configured your [environment variables](./../usage/environmental-variables.md).
The script will create the basic cluster repository structure as described [here](./../design/cluster-repository.md).
Except in very rare cases where a new feature requires it, you'll need and should execute this script only once.

## `apply.sh`

`managed-k8s/actions/apply.sh` is a wrapper script which can be used to create a yk8s on top of OpenStack.

The script triggers the execution of the following scripts:

  1. [`apply-terraform.sh`](#apply-terraformsh)
  2. [`apply-stage2.sh`](#apply-stage2sh)
  3. [`apply-stage3.sh`](#apply-stage3sh)
  4. [`apply-stage4.sh`](#apply-stage4sh)
  5. [`apply-stage5.sh`](#apply-stage5sh)
  6. [`apply-custom.sh`](#apply-customsh) *([if enabled](./../design/abstraction-layers.md#customization))*
  7. [`test.sh`](#testsh)

## `apply-terraform.sh`

<center>
  <img src="../img/apply-terraform.svg" alt="Apply Terraform Script Visualization" width="80%">
</center>

The `apply-terraform.sh`-script creates and updates the underlying cluster platform infrastructure
(sometimes also called harbour infrastructure layer) as defined by the [configuration](./../usage/cluster-configuration.md).
It also creates and updates the inventory files for ansible (`inventory/*/hosts`) and creates some variables in
the inventory (all created files have the `terraform_` prefix).

## `apply-stage2.sh`

<center>
  <img src="../img/apply-stage2.svg" alt="Apply Stage 2 Script Visualization" width="80%">
</center>

The `apply-stage2.sh`-script can be used to trigger the frontend preparation.
This script triggers an Ansible playbook which installs and prepares the frontend nodes,
including rolling out all users, setting up the basic infrastructure for C&H LBaaS and configuring wireguard.

## `apply-stage3.sh`

<center>
  <img src="../img/apply-stage3.svg" alt="Apply Stage 3 Script Visualization" width="80%">
</center>

This installs the Kubernetes worker and master nodes, including rolling out
all users, installing Kubernetes itself, deploying Rook, Prometheus etc.,
and configuring C&H LBaaS (also on the frontend nodes) if it is enabled.

## `apply-stage4.sh`

<center>
  <img src="../img/apply-stage4.svg" alt="Apply Stage 4 Script Visualization" width="80%">
</center>

> TODO: add details


## `apply-stage5.sh`

<center>
  <img src="../img/apply-stage5.svg" alt="Apply Stage 5 Script Visualization" width="80%">
</center>

> TODO: add details


## `apply-custom.sh`

<center>
  <img src="../img/apply-custom.svg" alt="Apply Custom Script Visualization" width="80%">
</center>

> TODO: add details


## `test.sh`

This runs the cluster test suite. It ensures basic functionality:

- Starting a pod & service
- Cinder volume block storage
- Rook ceph block storage (if enabled)
- Rook ceph shared filesystem storage (if enabled)
- C&H LBaaS (if enabled)
- Pod security policies (if enabled)
- Network policies (if enabled)
- Monitoring (if enabled)

## `destroy.sh`

Destroy the entire cluster and all of its data.

This is, obviously, destructive. Don’t run light-heartedly.

## `wg-up.sh`

When the Wireguard tunnel needs to be up, it is automatically setup by all `apply-*.sh`-scripts.

Bring up the WireGuard VPN to the cluster.

It tries to be smart about not doing anything stupid and ensuring that you’re
really connected to the correct cluster.

## `manage_roles.py`

This Python script should be used to create new Ansible roles and update and extend the meta information of existing ones.
The script can create and update roles with a minimal skeleton and an extended one (`--full`).

For further information on Ansible meta information take a look [here](https://galaxy.ansible.com/docs/contributing/creating_role.html#role-metadata).

```
usage: manage_roles.py [-h] {init,update} ...

positional arguments:
  {init,update}  Desired action to perform
    init         Initialize the skeleton for a new ansible role
    update       Update the existing ansible role. This action only updates the meta/main.yaml of the existing ansible role. If you want to create missing skeleton directory structure use `--create-missing` argument.

optional arguments:
  -h, --help     show this help message and exit
```

### Examples

Creating a new role into the k8s-base directory:

```python
python3 managed-k8s/actions/manage_roles.py init "ROLE_NAME" --path managed-k8s/k8s-base/roles
```

Updating the authors for all KSL roles:

```python
python3 actions/manage_roles.py update '*' --path k8s-service-layer/roles --author "AUTHORS"
```

## `update_inventory.py`

<center>
  <img src="../img/update-inventory.svg" alt="Update Inventory Script Visualization" width="80%">
</center>

The inventory updater is triggered automatically in advance of each action script.
It cleans up the inventory and ensures the latest variable/value pairs from your configuration file are used.

## `upgrade.sh`

This script can be used to trigger a Kubernetes upgrade.
More details about that can be found [here](./upgrading-kubernetes.md).

## `lib.sh`

The `lib.sh` is included by other action scripts and defines commonly used variables and function definitions.