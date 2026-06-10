.. _quick-start.openstack.required-system-resources:

Required System Resources
-------------------------

OpenStack Key-Pair
~~~~~~~~~~~~~~~~~~

Terraform is setup to provision an initial SSH pub key on the Openstack VMs it creates.
The key must be available in your Openstack project,
therefore `create an Openstack keypair <https://docs.openstack.org/horizon/latest/user/configure-access-and-security-for-instances.html#add-a-key-pair>`__.
Since the SSH configuration on the Kubernetes host nodes will be
hardened, your key has to be generated using one of the supported cryptographic
algorithm listed :ref:`here <ssh_algos>`. Note that RSA keys are not supported.

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
