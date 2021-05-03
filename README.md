### Pre-requisites

 - openstack project&user is created and ssh keypair is present
   - `TF_VAR_keypair` in `.envrc` must match the keypair name)
 - openrc is loaded
 - gitlab ssh access
- Python 3 and pip
  - `apt install python3-pip`
- venv (Included in the Python standard library, but apparently split into an extra package on Debian based distros)
  - `apt install python3-venv`
- Ansible 2.9+ (you can use requirements.txt to install it)
- Python OpenStack client (you can use requirements.txt to install it)
- GNU Make
- [jsonnet](https://github.com/google/jsonnet)
  - `GO111MODULE="on" go get github.com/google/go-jsonnet/cmd/jsonnet@v0.16.0` (maybe update the version)
- [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler#install)
  - `GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.4.0` (maybe update the version)
- terraform: https://www.terraform.io/downloads.html
  - move binary file to /usr/local/bin
  - sudo chmod +x if necessary
- sponge
  - `apt install moreutils`
- toml
  - `apt install python3-toml`
- jq
  - `apt install jq`
- wireguard
  - `apt install wireguard`
- current kernel headers:
  - `apt-get install linux-headers-$(uname -r)`
- passwordstore
  - `apt install pass`

## Prepare some dependencies

### Prepare WireGuard
```bash
mkdir ~/.wireguard/
(umask 0077 && wg genkey > ~/.wireguard/wg.key)
wg pubkey < ~/.wireguard/wg.key
```
- add the public key to https://gitlab.cloudandheat.com/lcm/wg_user
- make sure it gets added to master or make sure to use the proper branch in the cluster repository

### Prepare DirEnv
- Setting up [direnv](https://direnv.net/) is strongly recommended

### Prepare a virtual environment
```bash
mkdir ~/.venv/
python3 -m venv ~/.venv/managed-k8s/
```
## HowTo:

- [create a cluster repo](docs/admin/cluster-repo.md#creating-a-new-cluster-repository)

## Documentation

The documentation is created with mkdocs [0] and located under docs/.
 - To start the built-in dev-server, run `mkdocs serve -f mkdocs_<client|admin>.yml`
 - To compile the documentation to html, run `mkdocs build -f mkdocs_<client|admin>.yml`

[0] mkdocs.org
