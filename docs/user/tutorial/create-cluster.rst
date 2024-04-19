How to Create a Yaook Kubernetes Cluster
========================================

In this tutorial, we are going to set up a Yaook Kubernetes cluster using OpenStack virtual machines.


What Do We Need?
----------------

- Access to an OpenStack cloud with the following resources available:
    - At least 3 VMs need to be able to spawn:\
      by default we need 10 VMs (using our VM provider):
      17 VCPUs, 32 GB RAM and 4 floating IPs,\
      but you can configure the VMs later in ``config/config.toml``\

    .. note::

        The requirements may be different,
        e.g. you need one external IP and one gateway VM (1 VCPU and 1 GB RAM)
        for every availability zone.

    - An SSH key configured to access spawned instances
      and the name of that key known to you:
      via dashboard (Project → Compute → Key Pairs → Create Key Pair), or
      via `terminal <https://docs.openstack.org/python-openstackclient/pike/cli/command-objects/keypair.html>`__.
- A Unix shell environment for running the tutorial (called workstation)

.. note::

    The tutorial is based on Ubuntu 22.04

- The link to the :doc:`FAQ </user/guide/faq>` in case you hit trouble.
- You find some links to connect to us
  `here <https://gitlab.com/yaook/meta/-/wikis/home#chat>`__
  in case the FAQ can't help.

Now we are going to install all dependencies
that we need to create a Yaook cluster.

Prepare the Workstation
-----------------------

We begin with the packages required to be installed.
You can find the actual requirements
:ref:`here <initialization.install-system-requirements>`.

.. code:: console

    $ sudo apt install direnv \
        jq \
        moreutils \
        openssl \
        python3-pip \
        python3-poetry \
        python3-toml \
        python3-venv \
        uuid-runtime \
        wireguard

Install Terraform
-----------------

Terraform allows infrastructure to be expressed as code
in a simple, human-readable language called HCL (HashiCorp Configuration Language).
It reads configuration files and provides an execution plan of changes,
which can be reviewed for safety and then applied and provisioned.

To `install Terraform <https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform>`__,
we run these commands:

.. code:: console

    $ wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    $ echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    $ sudo apt update
    $ sudo apt install terraform

    $ # Check your installation
    $ terraform version

Install Helm
------------

Helm is the package manager for Kubernetes.
It is used to build Helm charts,
which are packages of Kubernetes resources
that are used to deploy apps to a cluster.
Please follow this `install instructions <https://helm.sh/docs/intro/install/>`__:

.. code:: console

    $ curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    $ sudo apt-get install apt-transport-https --yes
    $ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    $ sudo apt-get update
    $ sudo apt-get install helm

    $ # Check your installation
    $ helm version

Configure WireGuard
-------------------

For increased security,
the Kubernetes cluster is by default not directly accessible from the Internet.
Instead, you can only reach it via a VPN -
for that purpose, WireGuard (WG) is used.
In front of the actual Kubernetes cluster,
at least one gateway host is configured,
which exposes a SSH and WireGuard endpoint to the public.
These are your access points towards the whole cluster
until you expose services explicitly via the k8s mechanics.

.. code:: console

    $ # Create configuration directory for WG
    $ mkdir ~/.wireguard/

    $ # Create WG private key
    $ old_umask=$(umask)
    $ umask 0077
    $ wg genkey > ~/.wireguard/wg.key

    $ # Generate export the public key into a file
    $ wg pubkey < ~/.wireguard/wg.key > ~/.wireguard/wg.pub
    $ umask $old_umask

Get the OpenStack Configuration
-------------------------------

To be able to communicate with the OpenStack cloud,
you should fetch the ``openrc`` file
via the Dashboard of your cloud provider.
Make sure you are logged in
as the correct user
and with the correct project.
It should be possible to fetch that file from the dashboard
either by using the path ``project/api_access/openrc/``
or by clicking the menu entry to fetch it.

.. note::

    Your OpenStack credentials will be put into the Kubernetes cluster
    in order to integrate with OpenStack.
    Do not give third parties access to your cluster.
    In a productive setup,
    you would use application credentials
    or a separate user account.

Place the fetched file in an own directory:

.. code:: console

    $ # Create a folder for OpenStack openrc files
    $ mkdir ~/.openstack
    $ mv ~/Downloads/<openrc-file> ~/.openstack/my-cluster-repository-openrc.sh

Prepare the Cluster Repository
------------------------------

Create project folder:

.. code:: console

    $ mkdir ~/clusters
    $ cd ~/clusters

Clone ``yaook/k8s`` repository:

.. code:: console

    $ git clone https://gitlab.com/yaook/k8s.git

Create an empty git repository as your cluster repository:

.. code:: console

    $ git init my-cluster-repository

Copy templates with environment variables:

.. code:: console

    $ mkdir -p ~/.config/yaook-k8s/
    $ cp k8s/templates/yaook-k8s-env.template.sh ~/.config/yaook-k8s/env
    $ cp k8s/templates/envrc.template.sh my-cluster-repository/.envrc

Configure Direnv
----------------

``direnv`` is a simple way
to configure directory-specific environment variables
or automatically execute scripts -
so as soon as you switch in your directory
with the configuration data for your setup,
it will set required variables (such as credentials)
and source the Python virtual environment.

`For direnv to work, it needs to be hooked <https://direnv.net/docs/hook.html>`__
into your shell.

To load your Wireguard and OpenStack credentials,
edit the file ``~/.config/yaook-k8s/env``
by adapting the corresponding lines:

.. code:: console

    $ export wg_private_key_file="${HOME}/.wireguard/wg.key"
    $ export wg_user="<however_you_want_to_name_your_wg_user>"
    $ export TF_VAR_keypair="<name_of_the_ssh_public_key_in_your_openstack_account>"

    $ # Put that at the end of the file to load your OpenStack credentials:
    $ source_env ~/.openstack/<my-cluster-repository-openrc>.sh

Change the working dir into the new cluster repository:

.. code:: console

    $cd my-cluster-repository

You should be asked whether you want to unblock the ``.envrc``:

.. code:: console

    $ direnv allow

It should ask you for your OpenStack account password every time you go into that directory.

Initialising the Cluster Repository
-----------------------------------

.. code:: console

    $ bash ../k8s/actions/init-cluster-repository.sh
    $ git add .
    $ git commit -am 'Init the cluster repository'

To activate the virtual environment with all python dependencies,
just reload the ``direnv``:

.. code:: console

    $ direnv reload

Configure the Cluster
---------------------

As a next step
you can adjust the actual configuration for the k8s cluster,
e.g. the amount of master and worker nodes, flavors, image names.
The configuration file is named ``config/config.toml``.
For a full config reference click
:doc:`here </user/reference/cluster-configuration>`. Also have a close look to
all :doc:`terraform variables</developer/reference/terraform-docs>` that
can be set, you need to change some of them to fit to your OpenStack cluster.

Add the master and worker nodes to create your cluster with,
e.g. 2 master and 3 worker nodes.
Please have a look `here <https://docs.yaook.cloud/requirements/k8s-cluster.html#size>`__
for a recommended size
of a yaook kubernetes cluster.

.. code:: toml

   [terraform.masters.0]
   [terraform.masters.1]

   [terraform.workers.0]
   [terraform.workers.1]
   [terraform.workers.2]

Create a string of 16 random characters:

.. code:: console

    $ dd if=/dev/urandom bs=16 count=1 status=none | base64

In ``config/config.toml`` look for ``ANCHOR: ch-k8s-lbaas_config``,
and edit ``shared_secret`` with the output above:

.. code:: toml

    shared_secret = "<16_chars_generated_above>"

Look for a wireguard public key:

.. code:: console

    $ cat ~/.wireguard/wg.pub

Copy and paste it under
``ANCHOR: wireguard_config``, behind ``[wireguard]``.

.. code:: toml

    [[wireguard.peers]]
    pub_key = "<content_of_the_file_wg.pub>"
    ident   = "<your_wg_user_name>"  # see_above

Initialise Vault
----------------

Yaook/K8s uses `HashiCorp Vault <https://www.vaultproject.io/>`__
to store secrets (passwords, tokens, certificates, encryption keys, and other sensitive data).

.. note::

    For development purposes we are going to use a local Vault instance.
    This is not suited for productive development.

To allow using Vault in a local Docker container,
uncomment the following line in ``my-cluster-repository/.envrc``:

.. code:: bash

    export USE_VAULT_IN_DOCKER=true

Start the Docker container with Vault:

.. code:: console

    $ bash managed-k8s/actions/vault.sh

Uncomment the following line in ``.envrc``:

.. code:: bash

    . "$(pwd)/managed-k8s/actions/vault_env.sh"

Run

.. code:: console

    $ bash managed-k8s/tools/vault/init.sh
    $ bash managed-k8s/tools/vault/mkcluster-root.sh

Spawn the Cluster
-----------------

.. code:: console

    $ bash managed-k8s/actions/apply-all.sh

This will do a full deploy and consists of multiple stages.
You can also execute these steps manually one after another
instead of directly call ``apply-all.sh``.
In case you want to better understand what's going on -
simply check the :doc:`script </user/reference/actions-references>`
for what to execute in which order.

.. note::

    If you change the Cloud configuration in a destructive manner
    (decrease node counts, change flavors etc.)
    after having the previous config already deployed,
    these changes will not be applied by default
    to avoid havoc.
    For that case,
    you need to use an additional environment variable.
    You should not export that variable
    to avoid breaking things by accident.

    In ``config/config.toml`` add

    .. code:: toml

        [terraform]
        prevent_disruption = false

    Than run

    .. code:: console

        $ MANAGED_K8S_DISRUPT_THE_HARBOUR=true bash managed-k8s/actions/apply-terraform.sh

From this point on
you can use the k8s cluster for deploying any application.

Enjoy Your Cluster!
-------------------

Would you like to have a visualisation of your cluster?
Just install `k9s <https://k9scli.io/>`__ with

.. code:: console

    $ brew install derailed/k9s/k9s

and then run it:

.. code:: console

    $ k9s

The next time you would like to play with your Yaook Kubernetes cluster
(e.g., after a workstation reboot),
please don't forget to open the directory with your cluster to load the environment,
and to establish the WireGuard connection:

.. code:: console

    $ bash managed-k8s/actions/wg-up.sh

To tear down your cluster, set the following in ``config/config.toml``:

.. code:: toml

    [terraform]
    prevent_disruption = false

Than run:

.. code:: console

    $ MANAGED_K8S_NUKE_FROM_ORBIT=true MANAGED_K8S_DISRUPT_THE_HARBOUR=true MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/destroy.sh
