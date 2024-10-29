
Initialization
==============

.. _initialization.install-system-requirements:

Install System Requirements
---------------------------

YAOOK/K8s only has a single primary dependency: Nix. Everything else is fetched or built automatically.

`Nix <https://nixos.org>`__ is a declarative package manager
which powers NixOS but can also be installed as an additional separate package manager on any
other GNU/Linux distribution. This repository contains a flake.nix which references all necessary
dependencies locked to specific versions so everybody can produce the same identical environment.

1. `Install Nix <https://nixos.org/download.html#download-nix>`__
2. `Enable flake support <https://nixos.wiki/wiki/Flakes#Permanent>`__ by adding the following line to either ``~/.config/nix/nix.conf`` or ``/etc/nix/nix.conf``.

   .. code:: ini

      experimental-features = nix-command flakes
3. (Optional) Add our binary cache in ``/etc/nix/nix.conf``
   so you won't have to build anything from source

   .. code:: ini

      extra-substituters = https://yaook.cachix.org
      extra-trusted-public-keys = yaook.cachix.org-1:m85JtxgDjaNa7hcNUB6Vc/BTxpK5qRCqF4yHoAniwjQ=
4. Run ``nix shell`` in this directory to enter an environment with all requirements available
   If you use direnv, it will automatically load all requirements once you enter the directory.

We also strongly recommend installing and using:

-  `direnv <https://direnv.net/>`__

.. _initialization.required-system-resources:

Required System Resources
-------------------------

OpenStack Key-Pair
~~~~~~~~~~~~~~~~~~

Assuming you are deploying your YAOOK/K8s cluster on top of OpenStack, you
have to `create a ssh key pair in your OpenStack
project <https://docs.openstack.org/horizon/latest/user/configure-access-and-security-for-instances.html#add-a-key-pair>`__.
Since the SSH configuration on the Kubernetes host nodes will be
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

To deploy a YAOOK/K8s cluster, you need to create a git repository which will
serve as your :doc:`cluster repository </user/reference/cluster-repository>`:

1. Create an empty directory as your cluster repository:

   .. code:: console

      $ git init my-cluster-repository
      $ cd my-cluster-repository

2. Initialize the cluster repository:

   .. code:: console

      $ nix run "git+https://gitlab.com/yaook/k8s#init"

   .. hint::

      If you want to initialize YAOOK/K8s from a specific branch or tag, do:

      .. code:: console

         $ nix run "git+https://gitlab.com/yaook/k8s?ref=<branch1>#init" <branch2>

      where ``<branch1>`` selects the branch or tag from which the init script is to be run (defaults to ``devel``)
      and ``<branch2>`` selects the branch or tag that will be checked out in the submodule (defaults to the latest version known to ``branch1``).

      Typically, you'll want to set both to the same value.

   This init script will:

   -  Add all necessary submodules.
   -  Copy a configuration template to ``./config/`` if no
      config exists in the cluster repository yet.
   -  Update ``.gitignore`` to current standards.
   -  Add a ``.envrc`` template

3. Setup your environment variables:

   1. User specific variables (if not already exists):

      1. Copy the template located at
         ``managed-k8s/templates/yaook-k8s-env.template.sh``
         to ``~/.config/yaook-k8s/env``.

         .. code:: console

            $ cp $somewhere_else/k8s/templates/yaook-k8s-env.template.sh ~/.config/yaook-k8s/env

      2. Make the **user specific**
         :ref:`minimal changes <environmental-variables.minimal-required-changes>`
         to ``~/.config/yaook-k8s/env``.

   2. Make the **cluster specific**
      :ref:`minimal changes <environmental-variables.minimal-required-changes>`
      to ``./.envrc``.

3. Make sure they have taken effect by running ``direnv allow``.

.. _initialization.initialize-vault-for-a-development-setup:

Initialize Vault for a Development Setup
----------------------------------------

As of Summer 2023, YAOOK/K8s exclusively supports `HashiCorp Vault <https://vaultproject.io>`__
as backend for storing secrets.
Previously, `pass <https://www.passwordstore.org/>`__ was used.
For details on the use of Vault in YAOOK/K8s, please see the
:doc:`Use of HashiCorp Vault in YAOOK/K8s </developer/explanation/vault>` section.

To initialize a **local** Vault instance for **development purposes**, do the following:

1. Ensure that sourcing (comment it in) ``vault_env.sh`` is part of your ``.envrc``.

   .. code:: console

      $ sed -i '/#source \"\$(pwd)\/managed-k8s\/actions\/vault_env.sh\"/s/^#//g' .envrc

2. Ensure that setting ``USE_VAULT_IN_DOCKER`` to ``true`` is part of your ``.envrc``.

   .. code:: console

      $ sed -i '/export USE_VAULT_IN_DOCKER=false/s/false/true/g' .envrc
      $ sed -i '/#export USE_VAULT_IN_DOCKER=/s/^#//g' .envrc

   .. hint::

      If you are using rootless docker or podman,
      additionally set ``VAULT_IN_DOCKER_USE_ROOTLESS=true``
      in ``~/.config/yaook-k8s/env``

3. Don't forget to allow your changes:

   .. code:: console

      $ direnv allow .envrc

4. Start the docker container:

   .. code:: console

      $ ./managed-k8s/actions/vault.sh

   .. warning::
      This is not suited for productive deployments or production use,
      for many reasons!

5. Run the init command for vault

   .. code:: console

      $  ./managed-k8s/tools/vault/init.sh

6. If you are starting with a new created cluster run:

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
