.. _initialization.required-system-resources:

Required Local Resources
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
