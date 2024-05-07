Restoring Kubernetes' ability to sign certificates
==================================================

.. note::

   Requires at least version 6.0


Since YAOOK/k8s migrated
to :doc:`Hashicorp Vault </user/explanation/services/vault>` for managing PKI
and therefore clears the Kubernetes cluster root CA key from the control plane,
YAOOK/k8s clusters are not able to respond
to certificate signing requests (CSRs) anymore
since access to PKI keys ceased. [1]_

While in the long term we want to integrate Vault via a Kubernetes custom signer [2]_
which would redirect CSRs in Kubernetes directly to Vault,
for now we provide a workaround fix to restore the CSR functionality.
The fix must be explicitly turned on
by setting ``[kubernetes.controller_manager].enable_signing_requests=true`` in the config.

.. [1] Prior to YAOOK/k8s v6.0 CA private keys in Vault were never accessible.
.. [2] https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#custom-signers


Enabling the fix
----------------

.. attention::

   This weakens the security of your deployment!


1. Enable signing requests in the config

   Set ``[kubernetes.controller_manager].enable_signing_requests=true`` in config/config.toml

2. Configure k8s_control_plane Vault policy

   Executing 'tools/vault/init.sh' will take care of that.
   This assumes you already have a Vault instance running
   and reachable from your YAOOK/k8s shell environment.

   .. note::

      Requires a Vault root token

   .. code:: shell

      ./managed-k8s/tools/vault/init.sh

   ..

      The Kubernetes cluster root CA key is made available
      through the ``k8s-pki/cluster-root-ca`` secret
      in the Vault kv2 store of the cluster.
      The script adds a Vault policy rule (among other things)
      that grants read-only access to it for the control plane nodes role.


.. tabs::

   .. tab:: For a to be created cluster

      3. Create the Kubernetes cluster root CA and backup its key

         Executing 'tools/vault/mkcluster-root.sh' will take care of that.

         .. note::

            Requires a Vault root token

         .. code:: shell

            ./managed-k8s/tools/vault/mkcluster-root.sh

         ..

            The script creates the Kubernetes cluster root CA
            and backs up its private key
            to ``k8s-pki/cluster-root-ca`` in the Vault kv2 store of the cluster [3]_.


      4. Build the cluster
         using the :ref:`apply-all action <actions-references.apply-allsh>`

         This will copy and configure the Kubernetes cluster root CA key
         from Vault's kv2 store on all control plane nodes.


   .. tab:: For an existing cluster

      3. Recreate the Kubernetes cluster root CA and backup its key

         You must perform a complete root CA rotation,
         see :doc:`/user/guide/vault/vault-ca-rotation`

         Executing the preparation phase of 'tools/vault/rotate-root-ca-root.sh'
         will backup the Kubernetes cluster root CA key
         to ``k8s-pki/cluster-root-ca`` in the Vault kv2 store of the cluster [3]_.
         when the CA is recreated.

         .. tip:: SHORTCUT

            If you have access to the current CA key
            you may skip the root CA rotation
            and instead manually upload it to Vault's kv2 store:

            .. code:: shell

               clustername="$(yq --raw-output .vault_cluster_name inventory/yaook-k8s/group_vars/all/vault-backend.yaml)"
               vault kv put -mount="yaook/${clustername}/kv" k8s-pki/cluster-root-ca private_key=@current-ca.key


         .. tip:: SHORTCUT

            If you previously had the fix enabled and disabled it again
            and since then did not change the Kubernetes cluster root CA
            you may try to undelete the CA key in Vault's kv2 store:

            .. code:: shell

               clustername="$(yq --raw-output .vault_cluster_name inventory/yaook-k8s/group_vars/all/vault-backend.yaml)"
               export VAULT_TOKEN=$root_token
               ca_key_version="$(vault kv get -format=json -mount=yaook/${clustername}/kv k8s-pki/cluster-root-ca | jq .data.metadata.version)"
               vault kv undelete -versions="${ca_key_version}" -mount=yaook/${clustername}/kv k8s-pki/cluster-root-ca


      4. Run at least the ``k8s-master`` tag
         of the :ref:`apply-k8s-core action <actions-references.apply-k8s-coresh>`

         .. code:: shell

            AFLAGS="--tags k8s-master" ./managed-k8s/actions/apply-k8s-core.sh

         This will copy and configure the Kubernetes cluster root CA key
         from Vault's kv2 store on all control plane nodes.


5. Optional: Check that certificate signing is functional again now

   See the `Kubernetes documentation <https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/>`_
   on how to do that.


.. [3] The Kubernetes cluster root CA key can be read with
       ``VAULT_TOKEN=$root_token vault kv get -format=json -mount=yaook/${clustername}/kv k8s-pki/cluster-root-ca``.


Disabling the fix
-----------------

1. Set ``kubernetes.controller_manager.enable_signing_requests=false``

   .. code:: shell
      # If you're using config.toml:
      tomlq --in-place --toml-output '.kubernetes.controller_manager.enable_signing_requests=false' config/config.toml


.. tabs::

   .. tab:: For a to be created cluster

      2. Nothing to care about, go ahead as normal


   .. tab:: For an existing cluster

      2. Run at least the ``k8s-master`` tag
         of the :ref:`apply-k8s-core action <actions-references.apply-k8s-coresh>`

         .. note::

            Requires a Vault root token

         .. code:: shell

            AFLAGS="--tags k8s-master" ./managed-k8s/actions/apply-k8s-core.sh

         This will delete and deconfigure the Kubernetes cluster root CA key
         on all control plane nodes
         AND delete the backup in Vault's kv2 store (this requires a Vault root token).


         .. note::

            The key backup is not destroyed [4]_,
            you may still undelete it again later:

            .. note::

               Requires a Vault root token

            .. code:: shell

               clustername="$(yq --raw-output .vault_cluster_name inventory/yaook-k8s/group_vars/all/vault-backend.yaml)"
               ca_key_version="$(vault kv get -format=json -mount=yaook/${clustername}/kv k8s-pki/cluster-root-ca | jq .data.metadata.version)"
               vault kv undelete -versions="${ca_key_version}" -mount=yaook/${clustername}/kv k8s-pki/cluster-root-ca


            If you wish to completely remove the key backup from Vault, run:

            .. note::

               Requires a Vault root token

            .. code:: shell

               clustername="$(yq --raw-output .vault_cluster_name inventory/yaook-k8s/group_vars/all/vault-backend.yaml)"
               vault kv destroy -mount=yaook/${clustername}/kv \
                   -versions="0,$(
                       vault kv metadata get -format=json -mount=yaook/${clustername}/kv k8s-pki/cluster-root-ca \
                       | jq '.data.versions | keys_unsorted[] |  tonumber' | tr '\n' ','
                   )" \
                   k8s-pki/cluster-root-ca \
               && vault kv metadata delete -mount=yaook/${clustername}/kv k8s-pki/cluster-root-ca


.. [4] https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2#deleting-and-destroying-data
