.. _vault.tools:

Vault Tools
===========

The following scripts are provided in order to manage a Vault instance
for Tarook.

Please see
:ref:`Vault tooling variables <environmental-variables.vault-tooling-variables>`
for additional environment variables accepted by these tools.

-  ``tools/vault/init.sh``: Create policies and initialize the shared
   approle auth method. This will generally require a very privileged
   Vault entity (possibly a root token) to run and needs to be executed
   only once (and on policy updates).

-  ``tools/vault/mkcluster-root.sh``: Prepare a new cluster
   inside Vault, putting the root CA keys inside Vault. That means that
   control over vault implies permanent (until the Root CAs have been
   exchanged) control over the Kubernetes cluster.

-  ``tools/vault/mkcluster-intermediate.sh``: Prepare a new
   cluster inside Vault, with intermediate CAs only. This setup is not
   immediately usable, because the intermediate CAs first need to be
   signed with a root CA. Management of that root CA is out of scope for
   Tarook; this script is intended to integrate with your own
   separate root CA infrastructure. The certificate sign requests are
   provided as ``*.csr`` files in the working directory.

-  ``tools/vault/mkcsrs.sh``: Create new CSR files for intermediate CAs.
   This script should only be used with clusters which have been bootstrapped using
   ``mkcluster-intermediate.sh``, or equivalent.
   The CSRs created by this script must be signed with the (externally managed) root CA.
   The signed intermediates then can be imported into vault with the script below.
   The procedure is described in :ref:`vault.importing-new-intermediates`.

.. _vault.tools.load-signed-intermediates:

-  ``tools/vault/load-signed-intermediates.sh``: Load the
   signed intermediate CA files into the cluster. This script should
   only be used with clusters which have been bootstrapped using
   ``mkcluster-intermediate.sh``, or equivalent. As input, this script
   expects ``*.fullchain.pem`` files in its current working directory,
   one for each ``*.csr`` file emitted by ``mkcluster-intermediate.sh``.
   These files must contain two certificates: the signed intermediate
   certificate and, following that, the complete chain of trust up to
   the root CA, in this order.

-  ``tools/vault/dev-mkorchestrator.sh``: Creates an approle with the
   orchestrator policy. As this abuses the nodes approle auth plugin,
   this should not be used on productive clusters. In addition, every
   time this script is invoked, a new secret ID is generated without
   cleaning up the old one. This is generally fine for dev setups, but
   it’s another reason not to run this against productive clusters.

-  ``tools/vault/rmcluster.sh``: Deletes all data associated
   with the cluster from Vault. EXCEPTIONALLY DANGEROUS, so it always
   requires manual confirmation.

- ``tools/vault/update.sh``: Reinitializes the PKI engines, checks for
  leftovers inside vault and tries to reimport configurations for
  :ref:`etcd-backup <configuration-options.yk8s.k8s-service-layer.etcd-backup>`,
  and :ref:`Thanos <thanos.custom-bucket-management>`

- ``rotate-root-ca-intermediate.sh``: Needed for Root CA rotation by clusters
  which have been bootstrapped using ``mkcluster-intermediate.sh``, or equivalent.
  See :doc:`/user/guide/vault/vault-ca-rotation` for more information.

- ``rotate-root-ca-root.sh``: Needed for Root CA rotation by clusters
  which have their root CA managed inside Vault.
  See :doc:`/user/guide/vault/vault-ca-rotation` for more information.
