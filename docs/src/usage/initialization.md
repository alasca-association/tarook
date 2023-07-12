# Initialization

## Install System Requirements

### (Optional) Install requirements using Nix
[Nix](https://nixos.org) is a declarative package manager
which powers NixOS but can also be installed as an additional package manager on any
other distribution. This repository contains a flake.nix which references all necessary
dependencies which are locked to specific versions so everybody uses an identical environment.

1. [Install Nix](https://nixos.org/download.html#download-nix)
2. [Enable flake support](https://nixos.wiki/wiki/Flakes#Permanent) by adding the line
   ```
   experimental-features = nix-command flakes
   ```
   to either `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`
3. Run `nix shell` in this directory to enter the an environment with all requirements available
   If you use direnv, it will automatically load all requirements once you enter the directory.

<details>
<summary>Install system package dependencies</summary>

yaook/k8s requires the following packages:

- [poetry](https://github.com/python-poetry/install.python-poetry.org)
- jq
- moreutils (for `sponge`)
- wireguard
- pass
- uuid-runtime
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux)
- openssl

Please consult the documentation of your operation system to fulfill these dependencies.

</details>

<details>
<summary>Install Jsonnet</summary>

```console
# jsonnet (you may want to adjust the version)
$ GO111MODULE="on" go get github.com/google/go-jsonnet/cmd/jsonnet@v0.16.0

# jsonnet-bundler (you may want to adjust the version)
$ GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.4.0
```
</details>

<details>
<summary>Install Terraform</summary>
Follow [the upstream instructions on installing Terrafrom.](https://www.terraform.io/downloads)
</details>

<details>
<summary>Install helm</summary>
Follow [the upstream instructions on installing Helm.](https://helm.sh/docs/intro/install/)
</details>

We also strongly recommend installing and using:

- [direnv](https://direnv.net/)
- [python virtual environment](https://docs.python.org/3/tutorial/venv.html#creating-virtual-environments)
    - The suggested location for the virtual environment is `~/.venv/managed-k8s`, since this is the location, which is sourced by default in the [environment variables template](./environmental-variables.md#template).

## Required System Resources

### OpenStack Key-Pair

Assuming you are deploying your yk8s cluster on top of OpenStack, you have to [create a ssh key pair in your OpenStack project](https://docs.openstack.org/horizon/latest/user/configure-access-and-security-for-instances.html#add-a-key-pair). Since the SSH configuration on the kubernetes host nodes will be hardened, your key has to be in the format of a supported cryptographic algorithm. A list of these and an example of how to create such a key can be found in the [appendix](#appendix).

### WireGuard Key

```console
# Create working directory for wireguard
$ mkdir ~/.wireguard/

# Create wireguard key
$ (umask 0077 && wg genkey > ~/.wireguard/wg.key)

# Generate the public key
$ wg pubkey < ~/.wireguard/wg.key
```

## Create and Initialize Cluster Repository

To deploy a yk8s cluster, you need to create a git repository which will
serve as your [cluster repository](./../design/cluster-repository.md):

1. Create an empty directory as your cluster repository:
    ```console
    $ git init my-cluster-repository
    $ cd my-cluster-repository
    ```
1. Clone the `yaook/k8s` repository to a location **outside** of your cluster repository:
    ```console
    $ pushd $somewhere_else
    $ git clone https://gitlab.com/yaook/k8s.git
    $ popd
    ```
1. Setup your environment variables:
    1. Copy the template located at [`$somewhere_else/k8s/templates/envrc.template.sh`](./environmental-variables.md#template) to `./.envrc`.
        ```console
        $ cp $somewhere_else/k8s/templates/envrc.template.sh ./.envrc
        ```
    1. Make the [minimal changes](./environmental-variables.md#minimal-required-changes) to `./.envrc`.
    1. Make sure to they have taken effect by running `direnv allow`.
1. Initialize the cluster repository:
    ```console
    $ $somewhere_else/k8s/actions/init.sh
    ```
    This `init.sh` script will:
    - Add all necessary submodules.
    - Copy a `config.toml` template to `./config/config.toml` if no config exists in the cluster repository yet.
    - Update `.gitignore` to current standards.
1. In the `[defaults]` section of the [ansible configuration file](./cluster-configuration.md#ansible-configuration) `./managed-k8s/ansible/ansible.cfg`, set the environment variable `private_key_file` to the path of the private key file of the keypair, which in the `./.envrc` file was specified by the `$TF_VAR_keypair` environment variable.
1. Make sure poetry is up to date (otherwise installing the dependencies might fail), see https://python-poetry.org/docs/#installation
1. Activate the virtual environment with all python dependencies
   NOTE: This is handled automatically for you if you use the default .envrc
    ```console
    poetry shell -C managed-k8s
    ```

## Initialize Vault for a Development Setup

As of Summer 2022, yaook/k8s exclusively supports [HashiCorp Vault](https://vaultproject.io) as backend for storing secrets.
Previously, passwordstore was used.
For details on the use of Vault in yaook/k8s, please see the [Use of HashiCorp Vault in yaook/k8s](./../operation/vault.md) section.

To initialize a **local** Vault instance for **development purposes**, do the following:

1. Start the docker container:

    ```console
    ./managed-k8s/actions/vault.sh
    ```

    **Note:** This is not suited for productive deployments or production use,
    for many reasons!

2. Ensure that sourcing `managed-k8s/actions/vault_env.sh` is part of your `.envrc`.

3. Run `./managed-k8s/tools/vault/init.sh`

4. Run `./managed-k8s/tools/vault/mkcluster-root.sh devcluster`. Note that
  `devcluster` must be the same as the `cluster_name` set in the `config.toml`
  in the `[vault]` section.


## Appendix

### Allowed cryptographic algorithms for SSH

```yaml
{{#include ./../templates/ssh-hardening-vars.yaml}}
```

### SSH key generation

Creating a valid SSH key can be achieved by generating the key as follows, before uploading the public part to OpenStack:

```console
# Generating an ed25519 SSH key
$ ssh-keygen -t ed25519`
```
