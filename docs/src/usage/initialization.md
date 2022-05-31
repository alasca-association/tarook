# Initialization

## Install System Requirements

<details>
<summary>Install system package dependencies</summary>

```console
# managed-k8s system package dependencies
$ sudo apt install python3-pip python3-venv \
  python3-toml python3-cryptography moreutils \
  jq wireguard pass
```
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
    - Copy a `config.toml` template to `./config/config.toml`, if no config exists in the cluster repository yet.
    - Update `.gitignore` to current standards.
1. In the `[defaults]` section of the [ansible configuration file](./cluster-configuration.md#ansible-configuration) `./managed-k8s/ansible/ansible.cfg`, set the environment variable `private_key_file` to the path of the private key file of the keypair, which in the `./.envrc` file was specified by the `$TF_VAR_keypair` environment variable.
1. Install the python package dependencies:
    ```console
    python3 -m pip install -r managed-k8s/requirements.txt
    ```

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
