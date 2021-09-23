# Initialization

### Prepare WireGuard

```bash
mkdir ~/.wireguard/
(umask 0077 && wg genkey > ~/.wireguard/wg.key)
wg pubkey < ~/.wireguard/wg.key
```

## Empty git repository

To start out with a cluster, you need an (empty) git repository which will
serve as your cluster repository:

```console
$ git init my-test-cluster
$ cd my-test-cluster
```

## Pre-init requisites

* You have access to an OpenStack project and created a ssh [key pair](https://docs.openstack.org/horizon/latest/user/configure-access-and-security-for-instances.html#add-a-key-pair).

* You have set up your [environment variables](2-1-envvars.md).
  It's strongly recommended to use [direnv](https://direnv.net/) to
  properly setup your environment variables.

* You have installed all the system dependencies.
  ```bash
  # managed-k8s system package dependencies
  sudo apt install python3-pip python3-venv \
    python3-toml moreutils jq wireguard pass
  # current kernel headers
  apt install linux-headers-$(uname -r)
  ```

* It's strongly recommended to use a [virtual environment for Python](https://docs.python.org/3/tutorial/venv.html#creating-virtual-environments).

* You have installed the [jsonnet](https://github.com/google/jsonnet) and [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler#install) golang module.
  ```bash
  # jsonnet (you may want to adjust the version)
  GO111MODULE="on" go get github.com/google/go-jsonnet/cmd/jsonnet@v0.16.0

  # jsonnet-bundler (you may want to adjust the version)
  GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.4.0
  ```

* You have installed [Terraform](https://www.terraform.io/downloads.html)
  ```bash
  # Download the compressed terraform binary
  wget -q -O "terraform.zip" https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip
  # Extract the binary
  unzip -q terraform.zip
  # Move the binary
  mv terraform /usr/local/bin/terraform
  # sudo chmod +x if necessary
  ```

## Initialise cluster repository

To create the initial bare-minimum directory structure, a script is provided
in the `managed-k8s` project.

Clone the `managed-k8s` repository to a location **outside** of your cluster
repository:

```console
$ pushd "$somewhere_else"
$ git clone git@gitlab.com:yaook/k8s.git
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

- create the dir env, check the top of
  [Environment variables](2-1-envvars.md)

## Post-init requisites

After you have initialized your cluster, you should ensure that all the Python package dependencies are installed.

```bash
# pwd is the cluster-repository
python3 -m pip install -r k8s/requirements.txt
```

