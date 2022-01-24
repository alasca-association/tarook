# Initialization

## Pre-init requisites

* You have access to an OpenStack project and created a ssh [key pair](https://docs.openstack.org/horizon/latest/user/configure-access-and-security-for-instances.html#add-a-key-pair).
  * As the SSH configuration on the host nodes will be hardened, your key has to be in the format of a [supported cryptographic algorithm](#appendix).
* You have set up your [environment variables](./environmental-variables.md).
  * It's strongly recommended using [direnv](https://direnv.net/) to
    properly setup your environment variables.
  * A template file with default values is provided in [`templates/envrc.template.sh`](./environmental-variables.md#template).
  You **must** set some user-specific values though.
* You have installed all the [system dependencies](#appendix).
* It's strongly recommended using a [virtual environment for Python](https://docs.python.org/3/tutorial/venv.html#creating-virtual-environments).
  * We suggest to put it at `~/.venv/managed-k8s`.
* You have installed the [jsonnet](https://github.com/google/jsonnet) and [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler#install) golang module.
* You have installed [Terraform](#appendix).
* You have installed [helm](https://helm.sh/docs/intro/install/).

## Prepare WireGuard

```console
# Create working directory for wireguard
$ mkdir ~/.wireguard/

# Create wireguard key
$ (umask 0077 && wg genkey > ~/.wireguard/wg.key)

# Generate the public key
$ wg pubkey < ~/.wireguard/wg.key
```

## Create empty git repository

To start out with a cluster, you need an (empty) git repository which will
serve as your [cluster repository](./../design/cluster-repository.md):

```console
$ git init my-test-cluster
$ cd my-test-cluster
```

## Initialise cluster repository

To create the initial bare-minimum directory structure, a script is provided
in the [actions directory](./../operation/actions-references.md).

Clone the `yaook/k8s` repository to a location **outside** of your cluster
repository:

```console
$ pushd "$somewhere_else"
$ git clone git@gitlab.com:yaook/k8s.git
$ popd
```

Now you can run ``init.sh`` to bootstrap your cluster repository. Back in your
cluster repository directory, you now call the `init.sh` script from the
`managed-k8s` repository you just cloned:

```console
$ "$somewhere_else/k8s/actions/init.sh"
```

The `init.sh` script will:

- Add all necessary submodules
- Copy a config.toml template if no config exists in the cluster repository yet
- Update the .gitignore to current standards

## Post-init requisites

After you have initialized your cluster, you should ensure that all the Python package dependencies are installed.

```bash
# pwd is the cluster-repository
python3 -m pip install -r managed-k8s/requirements.txt
```

## Appendix

<details>
<summary>Allowed cryptographic algorithms for SSH</summary>

```yaml
{{#include ./../templates/ssh-hardening-vars.yaml}}
```
</details>

<details>
<summary>SSH key generation example</summary>

Creating a valid SSH key can be achieved by generating the key as follows, before uploading the public part to OpenStack:

```console
# Generating an ed25519 SSH key
$ ssh-keygen -t ed25519`
```

</details>

<details>
<summary>Install system dependencies</summary>

```console
# managed-k8s system package dependencies
$ sudo apt install python3-pip python3-venv \
  python3-toml moreutils jq wireguard pass

# current kernel headers
$ sudo apt install linux-headers-$(uname -r)
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

```console
# Download the compressed terraform binary
$ wget -q -O "terraform.zip" https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip

# Extract the binary
$ unzip -q terraform.zip

# Move the binary
$ mv terraform /usr/local/bin/terraform

# You may need allow execution of the binary
$ sudo chmod +x
```
</details>
