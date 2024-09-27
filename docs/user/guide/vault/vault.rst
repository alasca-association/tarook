Using Hashicorp Vault
=====================

Managing Clusters in Vault
--------------------------

The following scripts are provided in order to manage a Vault instance
for YAOOK/K8s.

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

-  ``tools/vault/import.sh``: Prepare a new cluster inside
   Vault by importing existing secrets from ``inventory/.etc``.
   Conceptually, this setup is identical to the setup provided by
   ``mkcluster-root.sh``. Please see
   :ref:`Migrating an existing cluster to Vault <vault.migrating-an-existing-cluster-to-vault>`
   for details.

-  ``tools/vault/mkcluster-intermediate.sh``: Prepare a new
   cluster inside Vault, with intermediate CAs only. This setup is not
   immediately usable, because the intermediate CAs first need to be
   signed with a root CA. Management of that root CA is out of scope for
   YAOOK/K8s; this script is intended to integrate with your own
   separate root CA infrastructure. The certificate sign requests are
   provided as ``*.csr`` files in the working directory.

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

.. _vault.migrating-an-existing-cluster-to-vault:

Migrating an existing cluster to an existing Vault
--------------------------------------------------

Before starting the migration, you must ensure that
:ref:`your environment <environmental-variables.vault-tooling-variables>`
has been setup properly **and** you initialized policies and approles in
the corresponding vault instance via ``tools/vault/init.sh`` (see
above).

There are two choices to migrate your cluster to Vault:

-  Root CA only
-  With Intermediate CA

.. tabs::

   .. tab:: Root CA only

      In this mode, the existing root CA keys will be copied into Vault. This
      is the simplest mode of operation, but may not be compliant with your
      security requirements, as the root CA keys are held “online” within
      Vault.

      Conceptually, this mode is similar to running ``mkcluster-root.sh`` (see
      above).

      To run a migration in this mode, call:

      .. code:: console

         $ managed-k8s/tools/vault/import.sh no-intermediates

      In addition, this mode takes care that the root CA files are actually
      usable as CAs (this is not ensured by the pre-vault LCM but somehow
      nothing cared).

   .. tab:: With Intermediate CA

      In this mode, a fresh intermediate CA key pair is created within Vault.
      The root CA keys are *not* imported into Vault. The import script
      generates Certificate Sign Requests for each intermediate CA. Before the
      cluster can be managed with Vault, it is thus required to sign the CSRs
      and load the signed certificates using ``load-signed-intermediates.sh``.

      Conceptually, this mode is similar to running
      ``mkcluster-intemediate.sh`` (see above).

      To start a migration in this mode, call:

      .. code:: console

         $ managed-k8s/tools/vault/import.sh with-intermediates

      This will print a message indicating that the CSRs have been written and
      to which files they have been written.

      In addition, like the ``no-intermediates`` mode, this mode takes care
      that the root CA files are actually usable as CAs (this is not ensured
      by the pre-vault LCM but somehow nothing cared).

      You now must use the CA key and certificates stored in ``inventory/`` to
      sign the respective CAs. How you do this is out of scope for this
      document, as it’ll highly depend on your organizations security policy
      requirements.

      Please see the documentation of ``load-signed-intermediates.sh`` above
      for details on the files expected by that script in order to load the
      signed certificates.

      Once you have provided the files, run:

      .. code:: console

         $ managed-k8s/tools/vault/load-signed-intermediates.sh

      to load the signed intermediate CA certificates into Vault.

Pivoting a cluster to host its own vault
----------------------------------------

“to pivot” means “to turn on an exact spot”. Here, we use this verb to
mean that an existing cluster, which is reliant on another Vault
instance, is changed such that relies on a Vault instance running within
that very same cluster.

Motivation
~~~~~~~~~~

As every YAOOK/K8s cluster needs a Vault instance it uses as a root of
trust and identity, the question becomes where to host that Vault
instance. An obvious answer is to run it inside Kubernetes. However, if
you were to use YAOOK/K8s again, where would *that* cluster have its
root of trust?

The answer is pivoting. When a cluster has no other Vault to rely on,
for instance because it is the root of trust in a site, it becomes
necessary that it hosts its own Vault. Despite sounding nonsensical,
this is an expressly supported use-case.

Terminology
~~~~~~~~~~~

Pivoting has two sub-scenarios, depending on whether the cluster which
is to be pivoted is already onboarded in a Vault or not. If the cluster
is already onboarded in a Vault instance (either productive or the local
docker-based development Vault), we call that *Case 1*. If the cluster
is not already onboarded in a Vault instance (i.e. a legacy cluster) we
call that *Case 2*.

In *Case 1*, we have to distinguish two Vault instances. We will call
the Vault instance with which the cluster has been deployed up to now
the *source Vault*. The Vault instance which we will spawn inside the
cluster and onto which the cluster will be pivoted will be called the
*target Vault*.

Prerequisites and Caveats
~~~~~~~~~~~~~~~~~~~~~~~~~

In order to migrate a cluster to host its own vault, the following
prerequisites are necessary:

-  Case 1: Migrating from a development or other Vault

   -  The cluster has been deployed or migrated to use another Vault
      (the *source Vault*). This can be the development Vault setup
      provided with YAOOK/K8s.

   -  The *source Vault* instance uses Raft.

   -  A sufficient amount of unseal key shares to unseal the *source
      Vault* are known.

-  Case 2: Migrating a cluster which is not upgraded to use Vault yet to
   use itself as Vault.

   -  The cluster has not been upgraded to use Vault yet.

-  No Vault has been deployed with YAOOK/K8s inside the cluster yet.

   .. note::

      If there already exists a Vault instance with YAOOK/K8s
      inside the cluster, all data inside it will be erased by following
      this procedure.

.. note::

   In general, it is not possible to pivot the cluster except by
   restoring a Vault raft snapshot into the cluster. This implies that
   *all* data from the source Vault is imported into the cluster. Thus, if
   you plan to pivot a cluster later, make sure to use a fresh Vault
   instance to avoid leaking data into the cluster you’d rather not have
   there.

.. note::

   An exception to the above rule exists if the cluster has been
   migrated and the original CA files still exist. In that case, it can be
   migrated *again* into the Vault it hosts itself. In this case, you may
   pretend you were doing *Case 2*, except that you need to trick the
   migration scripts. How to do that is left as an exercise to the reader.

Procedure
~~~~~~~~~

1. (Case 1 only) Obtain the number of unseal shares and the threshold
   for unsealing of the *source Vault*.

2. Enable ``k8s-service-layer.vault``, configure the backup and any
   other options you may need. Set the ``service_type`` to ``NodePort``
   and set the ``active_node_port`` to ``32048``.

   If Case 1 applies, set the number of unseal shares and the threshold
   to the same values as the *source Vault*.

   If Case 2 applies, you may choose an arbitrary number of unseal
   shares and an arbitrary threshold, in compliance with your security
   requirements.

3. Deploy the Vault by (re-)running `k8s-supplements`.

4. Verify that you can reach the Vault instance by running
   ``curl -k https://$nodeip:32048``, where you substitute ``$nodeip``
   with the IP of any worker or control plane node. (You should get some
   HTML back.)

.. tabs::

   .. tab:: Case 1: Migrating from a development or other Vault

      1. Take a raft snapshot of your *source Vault* by running
         ``vault operator raft snapshot save foo.snap`` with a sufficiently
         privileged token.

         Optionally, stop the *source Vault* to avoid accidentally
         interacting with it further.

         .. note::

            Continued use of the *source Vault* after taking a
            snapshot which is later loaded into the *target Vault* may or may
            not have security implications (serial number or token ID reuse or
            similar).

      2. Obtain the CA of the *target Vault* from Kubernetes using:

         .. code:: console

            $ kubectl -n k8s-svc-vault get secret vault-cert-internal -o json | jq -r '.data["ca.crt"]' | base64 -d > vault-ca.crt

      3. Configure access to the *target Vault*:

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

      4. Obtain a root token for the *target Vault* instance. As you have
         just freshly installed it with YAOOK/K8s, the root token will be in
         ``inventory/.etc/vault_root_token``.

      5. Scale the vault down to one replica.

      6. Delete the PVCs of the other replicas.

         .. note::

            We are entering the danger zone now. Double-check always
            that you are operating on the correct cluster and with the correct
            vault.

      7.
         .. danger::
            **THIS WILL IRREVERSIBLY DELETE THE DATA IN THE** *target
            Vault*. Double-check you are talking to the correct vault! Take a
            snapshot or whatever!

         Restore the snapshot from the *source Vault* in the *target Vault*.

         .. code:: console

            $ vault operator raft snapshot restore -force foo.snap

      8. Manually unseal the *target Vault*:

         .. code:: console

            $ kubectl -n k8s-svc-vault exec -it vault-0 -c vault -- vault operator unseal

         You now need to supply unseal key shares from the *source Vault*.

      9. Force vault to reset whatever it thinks about the cluster state.
         This is done by triggering a Raft recovery by placing a magic
         ``peers.json`` file in the raft data directory.

         First, we need to find the node ID:

         .. code:: console

            $ kubectl -n k8s-svc-vault exec -it vault-0 -c vault -- cat /vault/data/node-id; echo

         Then create the ``peers.json`` file:

         .. code:: json

            [
               {
                  "id": "...",
                  "address": "vault-0.vault-internal:8201",
                  "non_voter": false
               }
            ]

         (fill in the ``id`` field with the ID you found above)

         Upload the ``peers.json`` into the Vault node:

         .. code:: console

            $ kubectl -n k8s-svc-vault cp -c vault peers.json vault-0:/vault/data/raft/

         Restart the Vault node:

         .. code:: console

            $ kubectl -n k8s-svc-vault delete pod vault-0

         Once it comes up, unseal it again:

         .. code:: console

            $ kubectl -n k8s-svc-vault exec -it vault-0 -c vault -- vault operator unseal

         This should now show the ``HA Mode`` as active.

      10. Scale the cluster back up.

          .. code:: console

            $ kubectl -n k8s-svc-vault scale sts vault --replicas=3

      11. Unseal the other replicas:

          .. code:: console

            $ kubectl -n k8s-svc-vault exec -it vault-1 -c vault -- vault operator unseal
            $ kubectl -n k8s-svc-vault exec -it vault-2 -c vault -- vault operator unseal

          Congrats! You now have the data inside the K8s cluster.

      12. To test that YAOOK/K8s is able to talk to the Vault instance,
          you can now run any `k8s-core` with ``AFLAGS="-t vault-onboarded"``.

      13. Done!

   .. tab:: Case 2: Migrating a cluster which is not upgraded to use Vault yet to use itself as Vault

      1. Obtain the CA of the Vault from Kubernetes using:

         .. code:: console

            $ kubectl -n k8s-svc-vault get secret vault-cert-internal -o json | jq -r '.data["ca.crt"]' | base64 -d > vault-ca.crt


      2. Configure access to the Vault:

         .. code:: shell

            export VAULT_ADDR=https://$nodeip:32048
            export VAULT_CACERT="$(pwd)/vault-ca.crt"
            export VAULT_TOKEN=$(cat inventory/.etc/vault_root_token)

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

      3. Run ``managed-k8s/tools/vault/init.sh``

      4. Run ``managed-k8s/tools/vault/import.sh`` with the appropriate
         parameters.

      5. Done.
