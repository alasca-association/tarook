Using Hashicorp Vault
=====================

Managing Clusters in Vault
--------------------------

See :ref:`vault.tools` for details on provided scripts to set up
and manage a Vault as a secret backend for a Tarook cluster.

Using Vault to replace a long-lived admin.conf
----------------------------------------------

As Vault is able to issue certificates with the Kubernetes cluster CA, it is
possible to indirectly use Vault as identity provider for Kubernetes. An
example script is provided in ``tools/vault/k8s-login.sh`` and it can be used
like this:

.. code:: console

   $ umask 0077
   $ managed-k8s/tools/vault/k8s-login.sh K8S_SERVER_ADDR > admin.conf
   $ export KUBECONFIG="$(pwd)/admin.conf"

`K8S_SERVER_ADDR` must be the URL to the Kubernetes API (as that is,
unfortunately, part of the same configuration file as the credentials). The
generated ``admin.conf`` is a Kubernetes configuration file containing a
complete client configuration, including the private key.

You are welcome to use `k8s-login.sh` as an inspiration for your own tools.
Likely, you can make thing more specific to your environment and thus simpler
to use.

.. _vault.pivoting:

Pivoting a cluster to host its own vault
----------------------------------------

“to pivot” means “to turn on an exact spot”. Here, we use this verb to
mean that an existing cluster, which is reliant on another Vault
instance, is changed such that relies on a Vault instance running within
that very same cluster.

Motivation
~~~~~~~~~~

As every Tarook cluster needs a Vault instance it uses as a root of
trust and identity, the question becomes where to host that Vault
instance. An obvious answer is to run it inside Kubernetes. However, if
you were to use Tarook again, where would *that* cluster have its
root of trust?

The answer is pivoting. When a cluster has no other Vault to rely on,
for instance because it is the root of trust in a site, it becomes
necessary that it hosts its own Vault. Despite sounding nonsensical,
this is an expressly supported use-case.

Terminology
~~~~~~~~~~~

We have to distinguish two Vault instances. We will call
the Vault instance with which the cluster has been deployed up to now
the *source Vault*. The Vault instance which we will spawn inside the
cluster and onto which the cluster will be pivoted will be called the
*target Vault*.

Prerequisites and Caveats
~~~~~~~~~~~~~~~~~~~~~~~~~

In order to migrate a cluster to host its own vault, the following
prerequisites are necessary:

-  The cluster has been deployed or migrated to use another Vault
   (the *source Vault*). This can be the development Vault setup
   provided with Tarook.

-  The *source Vault* instance uses Raft.

-  A sufficient amount of unseal key shares to unseal the *source
   Vault* are known.

-  No Vault has been deployed with Tarook inside the cluster yet.

   .. note::

      If there already exists a Vault instance with Tarook
      inside the cluster, all data inside it will be erased by following
      this procedure.

.. note::

   In general, it is not possible to pivot the cluster except by
   restoring a Vault raft snapshot into the cluster. This implies that
   *all* data from the source Vault is imported into the cluster. Thus, if
   you plan to pivot a cluster later, make sure to use a fresh Vault
   instance to avoid leaking data into the cluster you’d rather not have
   there.

Procedure
~~~~~~~~~

1. Obtain the number of unseal shares and the threshold
   for unsealing of the *source Vault*.

2. Enable :ref:`k8s-service-layer.vault <configuration-options.yk8s.k8s-service-layer.vault>`,
   configure :doc:`automatic backups </user/guide/vault/automatic-backups>`
   and any other options you may need. Set the ``service_type`` to ``NodePort``
   and set the ``active_node_port`` to ``32048``.

   Set ``init_key_shares`` and ``init_key_threshold``
   to the same values as the *source Vault*.

3. Deploy the Vault by (re-)running `k8s-supplements`.

4. Verify that you can reach the Vault instance by running
   ``curl -k https://$nodeip:32048``, where you substitute ``$nodeip``
   with the IP of any worker or control plane node. (You should get some
   HTML back.)

5. Take a raft snapshot of your *source Vault* by running
   ``vault operator raft snapshot save foo.snap`` with a sufficiently
   privileged token.

   Optionally, stop the *source Vault* to avoid accidentally
   interacting with it further.

   .. note::

      Continued use of the *source Vault* after taking a
      snapshot which is later loaded into the *target Vault* may or may
      not have security implications (serial number or token ID reuse or
      similar).

6. Obtain the CA of the *target Vault* from Kubernetes using:

   .. code:: console

      $ kubectl -n k8s-svc-vault get secret vault-cert-internal -o json | jq -r '.data["ca.crt"]' | base64 -d > vault-ca.crt

7. Configure access to the *target Vault*:

   .. code:: console

      $ export VAULT_ADDR=https://$nodeip:32048
      $ export VAULT_CACERT="$(pwd)/vault-ca.crt"
      $ unset VAULT_TOKEN

   Verify connectivity using: ``vault status``.

   You should see something like:

   ::

      Key                     Value
      ---                     -----
      Seal Type               shamir
      Initialized             true
      Sealed                  false
      Total Shares            1
      Threshold               1
      Version                 1.12.1
      Build Date              2022-10-27T12:32:05Z
      Storage Type            raft
      Cluster Name            vault-cluster-4a491f8a
      Cluster ID              40dfd4ea-76ac-b2d0-bb9a-5a35c0a9bc9d
      HA Enabled              true
      HA Cluster              https://vault-0.vault-internal:8201
      HA Mode                 active
      Active Since            2023-03-01T18:42:41.824499649Z
      Raft Committed Index    44
      Raft Applied Index      44

   .. tip::

      Verify that you're talking to the *target Vault* by checking
      the *Active Since* timestamp.

8. Obtain a root token for the *target Vault* instance. As you have
   just freshly installed it with Tarook, the root token will be in
   ``etc/vault_root_token``.

9. Restore the snapshot from the *source Vault* in the *target Vault*.

   .. danger::
      **THIS WILL IRREVERSIBLY DELETE THE DATA IN THE** *target
      Vault*. Double-check you are talking to the correct vault! Take a
      snapshot or whatever!


   .. code:: console

      $ vault operator raft snapshot restore -force foo.snap

10. Trigger a restart of the target Vault

   .. code:: console

      $ kubectl rollout restart statefulset -n k8s-svc-vault vault

11. Manually unseal the *target Vault* instances as they come up. You'll need to supply unseal key shares from the *source Vault*.

   .. code:: console

      $ kubectl -n k8s-svc-vault exec -it vault-0 -c vault -- vault operator unseal
      $ kubectl -n k8s-svc-vault exec -it vault-1 -c vault -- vault operator unseal
      $ kubectl -n k8s-svc-vault exec -it vault-2 -c vault -- vault operator unseal

12. To test that Tarook is able to talk to the Vault instance,
      you can now run any `k8s-core` with ``AFLAGS="-t vault-onboarded"``.

13. Done!


.. _vault.importing-new-intermediates:

Importing new Intermediates
---------------------------

.. note::

   This section is relevant only for clusters which have been bootstrapped
   using ``mkcluster-intermediate.sh``, or equivalent.

Imported intermediates are valid for 1,5 years by default.
Usually, the (externally managed) root CA is valid for a longer period of time.
When the intermediates are about to expire,
they must be regenerated.
In the following the procedure for that is described:

.. note::

   A root token is required.

1. Create new CSRs

   .. code:: console

      $ bash managed-k8s/tools/vault/mkcsrs.sh

2. Optionally, you may also figure out the currently configured CA chains
   for comparison.
   These can be manually read from vault.
   You need to figure out the ID of the current issuer for each PKI engine for that.

   .. code:: console

      # k8s-pki
      $ vault list -detailed yaook/<CLUSTER_NAME>/k8s-pki/issuers
      $ vault read yaook/<CLUSTER_NAME>/k8s-pki/issuer/<ISSUER_ID>/ -format=json | jq -jr ".data.ca_chain[]" > k8s-pki.pem

      # etcd-pki
      $ vault list -detailed yaook/<CLUSTER_NAME>/etcd-pki/issuers
      $ vault read yaook/<CLUSTER_NAME>/etcd-pki/issuer/<ISSUER_ID>/ -format=json | jq -jr ".data.ca_chain[]" > etcd-pki.pem

      # k8s-front-proxy-pki
      $ vault list -detailed yaook/<CLUSTER_NAME>/k8s-front-proxy-pki/issuers
      $ vault read yaook/<CLUSTER_NAME>/k8s-front-proxy-pki/issuer/<ISSUER_ID>/ -format=json | jq -jr ".data.ca_chain[]" > k8s-front-proxy-pki.pem

3. Archive the files:

   .. code:: console

      $ tar -czvf "<CLUSTER_NAME>-intermediate-renewal-$(date --iso-8601=date).tar.gz" etcd-pki.pem k8s-front-proxy-pki.pem k8s-pki.pem etcd-pki.csr k8s-front-proxy-pki.csr k8s-pki.csr

   .. note::

      There is no need to check these into version control.

4. Get the CSRs signed by the externally managed root CA (out of scope of LCM).

5. Import the new signed intermediates:

   .. note::

      The script assumes that the full chains are present as the following files
      in your cluster repository:

      * ``$CLUSTER_REPOSITORY/k8s-cluster.fullchain.pem``
      * ``$CLUSTER_REPOSITORY/k8s-front-proxy.fullchain.pem``
      * ``$CLUSTER_REPOSITORY/k8s-etcd.fullchain.pem``

      Also refer to the :ref:`script's description<vault.tools>`.

   .. code:: console

      $ managed-k8s/tools/vault/load-signed-intermediates.sh

6. Do a full rollout:

   .. code:: console

      $ managed-k8s/actions/apply-all.sh

7. The temporary files (CSRs and CA chains) can be removed.
