Copying key-value secrets into a different Vault namespace
==========================================================

The following document describes how to copy
the key-value secrets that YAOOK/K8s manages in Vault
into a namespace based off a different vault_cluster_name.

General Procedure description
-----------------------------

The key-value secrets in currently used Vault namespace
based off the ``vault.cluster_name`` config setting
are enumerated.
With that all available secrets are copied
from the current namespace to another one that you specify.

Carrying out the copy
---------------------

Please substitute your current ``<clustername>`` in the following.
To verify your configured clustername you can use the following:

.. code:: console

  $ tomlq --raw-output '.vault.cluster_name' config/config.toml
  devcluster

``<new_clustername>`` is the cluster name
you intend to copy all key-value secrets to.

1. Create a new KV2 secret engine and mount it in the target Vault namespace

   This is usually done by creating a new Vault namespace with YAOOK/K8s.

   See :ref:`vault.tools.mkcluster-root` and :ref:`vault.tools.mkcluster-intermediate`.

2. Run the copying tool to copy the secrets

   .. code:: console

     $ ./managed-k8s/tools/vault/copy-kv-secrets-to-namespace.sh <new_clustername>

3. Optionally: Delete Vault namespace with old cluster name

   .. attention::

     YAOOK/K8s' Vault namespaces also include other secret engines,
     such as the PKI engine for the Kubernetes CA.
