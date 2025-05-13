
Initialization
==============

.. _initialization.install-system-requirements:

Install System Requirements
---------------------------

Tarook only has a single primary dependency: Nix. Everything else is fetched or built automatically.

`Nix <https://nixos.org>`__ is a declarative package manager
which powers NixOS but can also be installed as an additional separate package manager on any
other GNU/Linux distribution. This repository contains a flake.nix which references all necessary
dependencies locked to specific versions so everybody can produce the same identical environment.

1. Install Nix on a non NixOS system

   .. tabs::

      .. tab:: Via the official installer

         Follow the `Nix documentation <https://nixos.org/download.html#download-nix>`__ on how to install.

      .. tab:: From Ubuntu repositories

         Nix can also be installed from the Ubuntu repositories.
         The following has been tested on an Ubuntu 24.04 LTS system:

         .. code:: console

            $ # Run installation for debian managed nix multi-user package
            $ sudo apt update && sudo apt install nix-setup-systemd

            $ # Add current user to nix group
            $ sudo adduser $(whoami) nix-users

         Re-login to your seat (desktop session) or run the following command to use Nix right away:
         ``newgrp nix-users``. Note that the ``newgrp`` command starts a new shell and will only have
         effect within that shell.

2. `Enable Flake support <https://nixos.wiki/wiki/Flakes#Permanent>`__ by adding the following line to either ``~/.config/nix/nix.conf`` or ``/etc/nix/nix.conf``.

   .. code:: ini

      experimental-features = nix-command flakes

3. (Optional) Add our binary cache in ``/etc/nix/nix.conf``
   so you won't have to build anything from source

   .. code:: ini

      extra-substituters = https://nix-cache.tarook.cloud
      extra-trusted-public-keys = nix-cache.tarook.cloud-2:2X2yPTrpwmakhSgS83FVB2fKkG6IzfOJ1AGIIcvNyM0=

   .. note::

      The binary cache must be configured in ``/etc/nix/nix.conf``.
      Adding it to ``~/.config/nix/nix.conf`` is only doable if the current user
      is added as ``trusted-user`` in ``/etc/nix/nix.conf`` which would have security implications.

4. Restart the systemd service in order for the changes in ``nix.conf`` to take effect.

   .. code:: console

      $ sudo systemctl daemon-reload
      $ sudo systemctl restart nix-daemon

5. Install `direnv <https://direnv.net>`__ and configure its hook for your shell. This is not strictly necessary,
   but the rest of the guide assumes that direnv is available. You can enter the virtual environments and set
   all necessary environment variables manually instead, but then you're on your own.

.. _initialization.required-system-resources:

Required System Resources
-------------------------

OpenStack Key-Pair
~~~~~~~~~~~~~~~~~~

Assuming you are deploying your Tarook cluster on top of OpenStack, you
have to `create a ssh key pair in your OpenStack
project <https://docs.openstack.org/horizon/latest/user/configure-access-and-security-for-instances.html#add-a-key-pair>`__.
Since the SSH configuration on the Kubernetes host nodes will be
hardened, your key has to be generated using one of the supported cryptographic
algorithm listed :ref:`here <initialization.appendix>`. Note that RSA keys are not supported.

Example:

.. code:: console

   $ ssh-keygen -t ed25519
   $ openstack keypair create --public-key ~/.ssh/id_ed25519.pub <firstnamelastname-hostname-gendate>

WireGuard Key
~~~~~~~~~~~~~

As outlined in :ref:`user.explanation.architecture-overview`, Wireguard is used to access the cluster via the gateway nodes.

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

To deploy a Tarook cluster, you need to create a git repository which will
serve as your :doc:`cluster repository </user/reference/cluster-repository>`:

1. Create an empty directory as your cluster repository:

   .. code:: console

      $ git init my-cluster-repository
      $ cd my-cluster-repository

2. Initialize the cluster repository:

   .. code:: console

      $ nix run "git+https://gitlab.com/alasca.cloud/tarook/tarook#init"

   .. hint::

      If you want to initialize Tarook from a specific branch or tag, do:

      .. code:: console

         $ nix run "git+https://gitlab.com/alasca.cloud/tarook/tarook?ref=<branch1>#init" <branch2>

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

      Copy the template located at
      ``managed-k8s/templates/yaook-k8s-env.template.sh``
      to ``~/.config/yaook-k8s/env``.

      .. code:: console

         $ cp managed-k8s/templates/yaook-k8s-env.template.sh ~/.config/yaook-k8s/env

   2. Make the cluster- and user-specific
      :ref:`minimal changes <environmental-variables.minimal-required-changes>`
      to ``./.envrc`` and ``~/.config/yaook-k8s/env``.

   3. Make sure they have taken effect by running ``direnv allow``.

.. _initialization.initialize-vault-secrets-backend:

Initialize Vault secrets backend
--------------------------------

Tarook exclusively supports `HashiCorp Vault <https://vaultproject.io>`__
as backend for storing secrets.
For details on the use of Vault in Tarook, please see the
:doc:`Use of HashiCorp Vault in Tarook </developer/explanation/vault>` section.

.. _initialization.initialize-vault-for-a-development-setup:

At the time of writing
there is no documentation on how to create a production-ready Vault backend yet
but for testing purposes you may use the development setup [#vault-dev-setup-caveats]_
which automatically sets up a Vault instance in a local container.

.. [#vault-dev-setup-caveats] Note that the development Vault setup
   is built for ease-of-use
   and no special care is taken security-wise (stores unseal key and root token on disk)

.. note::

   We assume you have setup a container runtime like e.g. ``docker`` or ``podman``!

1. Ensure that sourcing (comment it in) ``vault_env.sh`` is part of your cluster ``.envrc``.

   .. code:: console

      $ sed -i '/#source \"\$(pwd)\/managed-k8s\/actions\/vault_env.sh\"/s/^#//g' .envrc

2. Enable the :ref:`development environment<environmental-variables.miscellaneous>`:

   .. code:: console

      $ sed -i '/#[[:blank:]]*export YAOOK_K8S_DEVSHELL=/s/^#//g' ~/.config/yaook-k8s/env

3. Ensure that setting ``USE_VAULT_IN_DOCKER`` to ``true`` is part of your cluster ``.envrc``.
   This will activate the Vault development setup.

   .. code:: console

      $ sed -i '/export USE_VAULT_IN_DOCKER=false/s/false/true/g' .envrc
      $ sed -i '/#export USE_VAULT_IN_DOCKER=/s/^#//g' .envrc

   .. hint::

      If you are using rootless docker or podman,
      additionally set ``VAULT_IN_DOCKER_USE_ROOTLESS=true``
      in ``~/.config/yaook-k8s/env``

4. Don't forget to allow your changes:

   .. code:: console

      $ direnv allow .envrc

5. Start the docker container:

   .. code:: console

      $ ./managed-k8s/actions/vault.sh

   .. warning::
      This is not suited for productive deployments or production use,
      for many reasons!


.. _initialization.appendix:

Appendix
--------

Allowed cryptographic algorithms for SSH
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. literalinclude:: /templates/ssh-hardening-vars.yaml
   :language: yaml
