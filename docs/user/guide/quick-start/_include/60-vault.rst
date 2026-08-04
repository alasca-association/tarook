1. Connecting the Vault backend

   If you are using the development Vault setup
   as suggested :ref:`earlier <quick-start.openstack.initialize-vault-secrets-backend>`
   the ``VAULT_ADDR`` and ``VAULT_TOKEN`` variables are automatically set.

   Otherwise ``VAULT_ADDR`` should be set in your cluster repository's ``.envrc``
   and ``VAULT_TOKEN`` be set manually.
   For the configuring the Vault backend ``VAULT_TOKEN`` needs to hold a root token.
   See also :ref:`environment-variables.secret-management`,
   `<https://developer.hashicorp.com/vault/docs/concepts/tokens>`_
   and `<https://developer.hashicorp.com/vault/docs/commands/login>`_.

2. Run the init command for Vault

   This creates the necessary policies and approles in the Vault backend.

   .. code:: shell

      tarook vault init

3. Setup secret engines for the cluster

   This sets up key-value and PKI secret engines in a Vault API namespace
   dedicated to the cluster.

   .. code:: shell

      tarook vault mkcluster-root


More details about Vault as backend is provided at :doc:`/user/guide/vault/vault`.

Any following actions expect that ``VAULT_TOKEN`` contains a Vault token
with policy ``yaook/orchestrator`` (recommended) or ``root``.

.. code:: shell

   vault token lookup -format=json | jq .data.policies
