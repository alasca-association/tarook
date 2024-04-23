# How to Create a Yaook Kubernetes Cluster

In this tutorial, we are going to set up a Yaook Kubernetes cluster using OpenStack virtual machines.


## What Do We Need?

- Access to an OpenStack cloud with the following resources available:
    - At least 3 VMs need to be able to spawn:\
      by default we need 10 VMs (using our VM provider):
      17 VCPUs, 32 GB RAM and 4 floating IPs,\
      but you can configure the VMs later in `config.toml`\
      **Note**: The requirements may be different,
      e.g. you need one external IP and one gateway VM (1 VCPU and 1 GB RAM)
      for every availability zone.
    - An SSH key configured to access spawned instances
      and the name of that key known to you:
      via dashboard (Project → Compute → Key Pairs → Create Key Pair), or
      via [terminal](https://docs.openstack.org/python-openstackclient/pike/cli/command-objects/keypair.html).
- A Unix shell environment for running the tutorial (called workstation)\
  **Note** : The tutorial is based on Ubuntu 22.04
- The link to the FAQ in case you hit trouble:\
    <a href="#">https://yaook.gitlab.io/k8s/devel/getting_started/faq.html</a>
- You find here some links to connect to us
  in case the FAQ can’t help:\
    <a href="#">https://gitlab.com/yaook/meta/-/wikis/home#chat</a>

Now we are going to install all dependencies
that we need to create a Yaook cluster.


## Prepare the Workstation

We begin with the packages required to be installed.
You can find the actual requirements [here](https://yaook.gitlab.io/k8s/devel/usage/initialization.html#install-system-requirements).
**Remember**: we are using Ubuntu 22.04 for this tutorial.

```bash
sudo apt install direnv \
                 jq \
                 moreutils \
                 openssl \
                 pass \
                 python3-pip \
                 python3-poetry \
                 python3-toml \
                 python3-venv \
                 uuid-runtime \
                 wireguard
```


## Install Terraform

Terraform allows infrastructure to be expressed as code
in a simple, human-readable language called HCL (HashiCorp Configuration Language).
It reads configuration files and provides an execution plan of changes,
which can be reviewed for safety and then applied and provisioned.

To [install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform), we run these commands:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform

# Check your installation
terraform version
```


## Install Helm

Helm is the package manager for Kubernetes.
It is used to build Helm charts,
which are packages of Kubernetes resources
that are used to deploy apps to a cluster.
Please follow this [install instructions](https://helm.sh/docs/intro/install/):

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Check your installation
helm version
```


## Configure WireGuard

For increased security,
the Kubernetes cluster is by default not directly accessible from the Internet.
Instead, you can only reach it via a VPN –
for that purpose, WireGuard (WG) is used.
In front of the actual Kubernetes cluster,
at least one gateway host is configured,
which exposes an SSH and WireGuard endpoint to the public.
These are your access points towards the whole cluster
until you expose services explicitly via the k8s mechanics.

```
# Create configuration directory for WG
mkdir ~/.wireguard/

# Create WG private key
old_umask=$(umask)
umask 0077
wg genkey > ~/.wireguard/wg.key

# Generate export the public key into a file
wg pubkey < ~/.wireguard/wg.key > ~/.wireguard/wg.pub
umask $old_umask
```


## Configure GPG
<!---
[comment by Steve]:
This probably can be dropped at all
as everything should be migrated to be stored in vault.
But honestly, I am unsure
if we currently still require a GPG key to be around though
so we can also keep it for now.
--->

Some credentials are stored in the password-manager pass,
for example the private key of the WG VPN.
Therefore, you need to have a GPG key available.
If you don’t have one, you can generate one by executing the following snippet. Please adapt the name and email address to use, as well as the password.

```bash
gpg --batch --gen-key <<EOF
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Name-Real: <Your Name>
Name-Email: <your.name@mail.provider>
Expire-Date: 0
Passphrase: <your password>
EOF
```


## Get the OpenStack Configuration

To be able to communicate with the OpenStack cloud,
you should fetch the `openrc` file
via the Dashboard of your cloud provider.
Make sure you are logged in
as the correct user
and with the correct project.
It should be possible to fetch that file from the dashboard
either by using the path `project/api_access/openrc/`
or by clicking the menu entry to fetch it.

**Note:**
Your OpenStack credentials will be put into the Kubernetes cluster
in order to integrate with OpenStack.
Do not give third parties access to your cluster.
In a productive setup,
you would use application credentials
or a separate user account.

Place the fetched file in an own directory:

```bash
# Create a folder for OpenStack openrc files
mkdir ~/.openstack
mv ~/Downloads/<openrc-file> ~/.openstack/my-cluster-repository-openrc.sh
```


## Prepare the Cluster Repository

Create project folder:
```bash
mkdir ~/clusters
cd ~/clusters
```

Clone `yaook/k8s` repository:
```bash
git clone https://gitlab.com/yaook/k8s.git
```

Create an empty git repository as your cluster repository:
```bash
git init my-cluster-repository
```

Copy templates with environment variables:
```bash
mkdir -p ~/.config/yaook-k8s/
cp k8s/templates/yaook-k8s-env.template.sh ~/.config/yaook-k8s/env
cp k8s/templates/envrc.template.sh my-cluster-repository/.envrc
```


## Configure Direnv

`direnv` is a simple way
to configure directory-specific environment variables
or automatically execute scripts –
so as soon as you switch in your directory
with the configuration data for your setup,
it will set required variables (such as credentials)
and source the Python virtual environment.

[For `direnv` to work, it needs to be hooked](https://direnv.net/docs/hook.html) into your shell.


To load your Wireguard and OpenStack credentials,
edit this file `~/.config/yaook-k8s/env` as follows
by adapting the corresponding lines:

```
export wg_private_key_file="${HOME}/.wireguard/wg.key"
export wg_user="<however_you_want_to_name_your_wg_user>"
export TF_VAR_keypair="<name_of_the_ssh_public_key_in_your_openstack_account>"

# Put that at the end of the file to load your OpenStack credentials:
source_env ~/.openstack/<my-cluster-repository-openrc>.sh
```

Change the working dir into the new cluster repository:
```bash
cd my-cluster-repository
```

You should be asked whether you want to unblock the `.envrc`:
```bash
direnv allow
```

It should ask you for your OpenStack account password every time you go into that directory.


## Initialising the Cluster Repository
```bash
bash ../k8s/actions/init.sh
git add .
git commit -am 'Init the cluster repository'
```

To activate the virtual environment with all python dependencies,
just reload the `direnv`:
```bash
direnv reload
```


## Configure the Cluster

As a next step
you can adjust the actual configuration for the k8s cluster,
e.g. the amount of master and worker nodes, flavors, image names.
The configuration file is named `config/config.toml`.
For a full config reference click [here](https://yaook.gitlab.io/k8s/devel/usage/cluster-configuration.html).

Adopt the amount of nodes,
e.g. one worker node and one master node.
Please have a look [here](https://docs.yaook.cloud/requirements/k8s-cluster.html#size)
for a recommended size
of a yaook kubernetes cluster.
```
masters = 1
workers = 1
```

Create a string of 16 random characters:
```bash
dd if=/dev/urandom bs=16 count=1 status=none | base64
```
In `config.toml` look for `ANCHOR: ch-k8s-lbaas_config`,
and edit `shared_secret` with the output above:
```
shared_secret = "<16_chars_generated_above>"
```

Look for a wireguard public key:
```bash
cat ~/.wireguard/wg.pub
```
Copy and paste it under
`ANCHOR: wireguard_config`, behind `[wireguard]`.
```
[[wireguard.peers]]
pub_key = "<content_of_the_file_wg.pub>"
ident   = "<your_wg_user_name_(see_above)>"
```

Look for `ANCHOR: passwordstore_configuration` with this command:
```bash
gpg --keyid-format LONG -K <test.user@mail.fake>
```
and add the output behind `[passwordstore]`:

```
[[passwordstore.additional_users]]
ident = <your GPG key mail address, e.g. "test.user@mail.fake">
gpg_id = <yourt GPG long ID, e.g. "238F9AED92DD4C36148F45F68846E45B1F4D115F">
```


## Initialise Vault
Yaook/K8s uses [HashiCorp Vault](https://www.vaultproject.io/)
to store secrets (passwords, tokens, certificates, encryption keys, and other sensitive data).
**Note:** For development purposes we are going to use a local Vault instance.
This is not suited for productive development.
To allow using Vault in a local Docker container,
uncomment the follow line in `my-cluster-repository/.envrc`:
```
export USE_VAULT_IN_DOCKER=true
```

Start the Docker container with Vault:
```bash
bash managed-k8s/actions/vault.sh
```
Uncomment the follow line in `.envrc`:
```
. "$(pwd)/managed-k8s/actions/vault_env.sh"
```
Run
```bash
bash managed-k8s/tools/vault/init.sh

# <devcluster> must match [vault.cluster_name] of config.toml
bash managed-k8s/tools/vault/mkcluster-root.sh devcluster
```


## Spawn the Cluster

```bash
bash managed-k8s/actions/apply.sh
```

This will do a full deploy and consists of multiple stages.
You can also execute these steps manually one after another
instead of directly call `apply.sh`.
In case you want to better understand what’s going on –
simply check the [script](https://yaook.gitlab.io/k8s/devel/operation/actions-references.html)
for what to execute in which order.

**Note**:
If you change the Cloud configuration in a destructive manner
(decrease node counts, change flavors etc.)
after having the previous config already deployed,
these changes will not be applied by default
to avoid havoc.
For that case,
you need to use an additional environment variable.
You should not export that variable
to avoid breaking things by accident.

```bash
MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply.sh
```

From this point on
you can use the k8s cluster for deploying any application.


## Enjoy Your Cluster!

Would you like to have a visualisation of your cluster?
Just install [k9s](https://k9scli.io/) with
```bash
brew install derailed/k9s/k9s
```
and then run it:
```bash
k9s
```

The next time you would like to play with your Yaook Kubernetes cluster
(e.g., after a workstation reboot),
please don't forget to open the directory with your cluster to load the environment,
and to establish the WireGuard connection:
```bash
bash managed-k8s/actions/wg-up.sh
```

To tear down your cluster, you can run:
```bash
MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/destroy.sh
```
