
Initialization
==============

.. _initialization.install-system-requirements:

Install System Requirements
---------------------------

.. tabs::

   .. tab:: Install requirements manually

      .. raw:: html

         <details>
         <summary>Install system package dependencies</summary>


      yaook/k8s requires the following packages:

      - `python3-poetry <https://github.com/python-poetry/install.python-poetry.org>`__
        - please note that a version > v1.5.0 is required
      - jq
      - moreutils (for ``sponge``)
      - wireguard
      - uuid-runtime
      - openssl

      For Debian-based distros you can do:

      .. code:: console

         $ sudo apt install python3-poetry jq moreutils wireguard uuid-runtime kubectl openssl

      Additionally, `kubectl <https://kubernetes.io/docs/tasks/tools/install-kubectl-linux>`__
      is needed.

      Furthermoe, please consult the documentations for your operation system to fulfill
      the following dependencies.

      .. raw:: html

         </details>

      .. raw:: html

         <details>
         <summary>Install Jsonnet</summary>

      .. code:: console

         $ # jsonnet (you may want to adjust the version)
         $ GO111MODULE="on" go get github.com/google/go-jsonnet/cmd/jsonnet@v0.16.0

         $ # jsonnet-bundler (you may want to adjust the version)
         $ GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.4.0

      .. raw:: html

         </details>

      .. raw:: html

         <details>
         <summary>Install Terraform</summary>

      Follow `the upstream instructions on installing Terraform <https://www.terraform.io/downloads>`__.

      .. raw:: html

         </details>

      .. raw:: html

         <details>
         <summary>Install helm</summary>

      Follow `the upstream instructions on installing
      Helm. <https://helm.sh/docs/intro/install/>`__

      .. raw:: html

         </details>

   .. tab:: Install requirements using Nix

      `Nix <https://nixos.org>`__ is a declarative package manager
      which powers NixOS but can also be installed as an additional package manager on any
      other distribution. This repository contains a flake.nix which references all necessary
      dependencies which are locked to specific versions so everybody uses an identical environment.

      1. `Install Nix <https://nixos.org/download.html#download-nix>`__
      2. `Enable flake support <https://nixos.wiki/wiki/Flakes#Permanent>`__ by adding the line

         .. code:: ini

            experimental-features = nix-command flakes

         to either ``~/.config/nix/nix.conf`` or ``/etc/nix/nix.conf``
      3. Run ``nix shell`` in this directory to enter an environment with all requirements available
         If you use direnv, it will automatically load all requirements once you enter the directory.

We also strongly recommend installing and using:

-  `direnv <https://direnv.net/>`__

.. _initialization.required-system-resources:

Required System Resources
-------------------------

OpenStack Key-Pair
~~~~~~~~~~~~~~~~~~

Assuming you are deploying your yk8s cluster on top of OpenStack, you
have to `create a ssh key pair in your OpenStack
project <https://docs.openstack.org/horizon/latest/user/configure-access-and-security-for-instances.html#add-a-key-pair>`__.
Since the SSH configuration on the kubernetes host nodes will be
hardened, your key has to be in the format of a supported cryptographic
algorithm. A list of these and an example of how to create such a key
can be found in the :ref:`appendix <initialization.appendix>`.

WireGuard Key
~~~~~~~~~~~~~

.. code:: console

   $ # Create working directory for wireguard
   $ mkdir ~/.wireguard/

   $ # Create wireguard key
   $ (umask 0077 && wg genkey > ~/.wireguard/wg.key)

   $ # Generate the public key
   $ wg pubkey < ~/.wireguard/wg.key

.. _initialization.create-and-initialize-cluster-repository:

Create and Initialize Cluster Repository
----------------------------------------

To deploy a yk8s cluster, you need to create a git repository which will
serve as your :doc:`cluster repository </user/reference/cluster-repository>`:

1. Create an empty directory as your cluster repository:

   .. code:: console

      $ git init my-cluster-repository
      $ cd my-cluster-repository

2. Clone the ``yaook/k8s`` repository to a location **outside** of your
   cluster repository:

   .. code:: console

      $ pushd $somewhere_else
      $ git clone https://gitlab.com/yaook/k8s.git
      $ popd

3. Setup your environment variables:

   1. User specific variables (if not already exists):

      1. Copy the template located at
         ``$somewhere_else/k8s/templates/yaook-k8s-env.template.sh``
         to ``~/.config/yaook-k8s/env``.

         .. code:: console

            $ cp $somewhere_else/k8s/templates/yaook-k8s-env.template.sh ~/.config/yaook-k8s/env

      2. Make the **user specific**
         :ref:`minimal changes <environmental-variables.minimal-required-changes>`
         to ``~/.config/yaook-k8s/env``.

   2. Cluster specific variables:

      1. Copy the template located at
         :ref:`$somewhere_else/k8s/templates/envrc.template.sh <environmental-variables.template>`
         to ``./.envrc``.

         .. code:: console

            $ cp $somewhere_else/k8s/templates/envrc.template.sh ./.envrc

      2. Make the **cluster specific**
         :ref:`minimal changes <environmental-variables.minimal-required-changes>`
         to ``./.envrc``.
   3. Make sure they have taken effect by running ``direnv allow``.

4. Initialize the cluster repository:

   .. code:: console

      $ $somewhere_else/k8s/actions/init-cluster-repo.sh

   This ``init.sh`` script will:

   -  Add all necessary submodules.
   -  Copy a ``config.toml`` template to ``./config/config.toml`` if no
      config exists in the cluster repository yet.
   -  Update ``.gitignore`` to current standards.

5. Make sure poetry is up to date (otherwise installing the dependencies might fail),
   see `here <https://python-poetry.org/docs/#installation>`__

6. Activate the virtual environment with all python dependencies

   .. note::

      This is handled automatically for you if you use the default ``.envrc``

   .. code:: console

      $ poetry shell -C managed-k8s

.. _initialization.initialize-vault-for-a-development-setup:

Initialize Vault for a Development Setup
----------------------------------------

As of Summer 2023, yaook/k8s exclusively supports `HashiCorp Vault <https://vaultproject.io>`__
as backend for storing secrets.
Previously, `pass <https://www.passwordstore.org/>`__ was used.
For details on the use of Vault in yaook/k8s, please see the
:doc:`Use of HashiCorp Vault in yaook/k8s </developer/explanation/vault>` section.

To initialize a **local** Vault instance for **development purposes**, do the following:

1. Start the docker container:

   .. code:: console

      $ ./managed-k8s/actions/vault.sh


   .. Note::
      This is not suited for productive deployments or production use,
      for many reasons!

   .. Note::
      If you are using rootless docker or podman, set ``VAULT_IN_DOCKER_USE_ROOTLESS=true``
      in ``~/.config/yaook-k8s/env``

2. Ensure that sourcing (comment in) ``vault_env.sh`` is part of your ``.envrc``.

   .. code:: console

      $ sed -i '/#source \"\$(pwd)\/managed-k8s\/actions\/vault_env.sh\"/s/^#//g' .envrc

3. Run the init command for vault

   .. code:: console

      $  ./managed-k8s/tools/vault/init.sh

4. If you are starting with a new created cluster run:

   .. code:: console

      $ ./managed-k8s/tools/vault/mkcluster-root.sh

   If you are migrating an old cluster see
   :ref:`here <vault.migrating-an-existing-cluster-to-vault>`.


.. _initialization.appendix:

Appendix
--------

Allowed cryptographic algorithms for SSH
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. literalinclude:: /templates/ssh-hardening-vars.yaml
   :language: yaml

SSH key generation
~~~~~~~~~~~~~~~~~~

Creating a valid SSH key can be achieved by generating the key as
follows, before uploading the public part to OpenStack:

.. code:: console

   $ # Generating an ed25519 SSH key
   $ ssh-keygen -t ed25519`
