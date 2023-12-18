Root Certificate Authority Rotation
===============================================

The following document describes how to rotate
the certificate authority certificates in use and renewing
certificates for all components with a new root CA.

This procedure is **not** necessary if you don't
want to exchange your root CA but just renew certificates.

Further information can be found
`in the official Kubernetes documentation <https://kubernetes.io/docs/tasks/tls/manual-rotation-of-ca-certificates/>`__.

General Procedure description
-----------------------------

There are four Vault PKI engines configured for each cluster:
- k8s-pki
- etcd-pki
- calico-pki
- k8s-front-proxy-pki

We must rotate the certificate authorities for each of them.
To do so, a new issuer is added to each PKI engine.
Depending on your setup, you may use root CAs or intermediate CAs
for that.

After a new issuer has been added to each PKI engine,
we start the transition process.
This process consists of two phases.

In the first phase,
the new CAs are added to the accepted CA bundles for each
Kubernetes control plane component and made available in the cluster.
To accept the new CA bundles, each component must be restarted.
Furthermore, kubeconfigs get renewed but certificates in use
by control plane components get not, yet.
After this phase, the renewed kubeconfigs should be spread.
Each workload will and must be restarted to renew its credentials
(i.e. API tokens, ConfigMaps and Secrets).

In the second phase,
the old CAs are removed from the accepted CA bundles for each
Kubernetes control plane component.
Furthermore, certificates for all Kubernetes control plane
components get renewed and issued by the newly introduced issuer.
To omit the old CA and ensure connectivity among components,
each component must be restarted.
Each workload will and must be restarted to renew its credentials.
As we renewed the kubeconfigs with the new issuer in the first phase,
we're still able to talk to the Kubernetes API during this phase.

.. note::

  In each phase we must update the CA ConfigMap for the prometheus-adapter
  and rollout restart it as it is otherwise unable to scrape metrics.
  This is done automatically, but we may fly blind for a few moments.

Executing a CA rotation
-----------------------

Please substitute your ``<clustername>`` in the following.
To verify your configured clustername you can use the following:

.. code:: bash

  $ cat config/config.toml | python3 -c 'import toml, sys; toml.dump(toml.load(sys.stdin).get("vault"), sys.stdout)'
  cluster_name = "devcluster"

Phase 1
^^^^^^^

1. Start with single issuer which is currently the default

   .. code:: bash

    # Verify currently configured issuers
    $ vault list -detailed yaook/<clustername>/k8s-pki/issuers
    Keys                                    is_default    issuer_name
    ----                                    ----------    -----------
    06a9511a-ffd2-2ce3-bd01-2cb2180a5e51    true          n/a
    $ vault list -detailed yaook/<clustername>/etcd-pki/issuers
    [...]
    $ vault list -detailed yaook/<clustername>/calico-pki/issuers
    [...]
    $ vault list -detailed yaook/<clustername>/k8s-front-proxy-pki/issuers
    [...]

2. Add a new issuer which will be called ``next`` to all PKIs

   .. tabs::

      .. tab:: Without intermediates

        .. code:: bash

          $ ./managed-k8s/tools/vault/rotate-root-ca-root.sh <clustername> prepare

          # Verify
          $ vault list -detailed yaook/<clustername>/k8s-pki/issuers
          $ vault list -detailed yaook/<clustername>/etcd-pki/issuers
          $ vault list -detailed yaook/<clustername>/calico-pki/issuers
          $ vault list -detailed yaook/<clustername>/k8s-front-proxy-pki/issuers

      .. tab:: With intermediates

        1. Generate CSRs

          .. code:: bash

            $ ./managed-k8s/tools/vault/rotate-root-ca-intermediate.sh <clustername> prepare

        2. Sign the generated CSRs

        3. Import the signed certificates as new issuer "next"

          .. code:: bash

            $ ./managed-k8s/tools/vault/rotate-root-ca-intermediate.sh <clustername> load-signed-intermediates

            # Verify
            $ vault list -detailed yaook/<clustername>/k8s-pki/issuers
            $ vault list -detailed yaook/<clustername>/etcd-pki/issuers
            $ vault list -detailed yaook/<clustername>/calico-pki/issuers
            $ vault list -detailed yaook/<clustername>/k8s-front-proxy-pki/issuers

3. If you've created your cluster before 2024, you must additionally update your vault policies

  .. note::

    You must have sourced a root token to update vault policies.

  .. code:: bash

    $ ./managed-k8s/tools/vault/init.sh


4. Run the rotation action to roll out both CAs in the cluster and create kubeconfigs
   issued by the "next" CA but trusting both CAs.

   .. code:: bash

     $ MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/rotate-ca.sh -n

5. Verify workload is able to come back up

6. Verify the logs of all Kubernetes components

7. Run the smoke tests

   .. code:: bash

     $ ./managed-k8s/actions/test.sh

8. Distribute the renewed kubeconfig(s)

Phase 2
^^^^^^^

After you spread the kubeconfigs, do the following:

1. Rotate the issuer and set the new one has default,
   mark the old issuer as outdated.

   .. tabs::

      .. tab:: Without intermediates

        .. code::

          $ ./managed-k8s/tools/vault/rotate-root-ca-root.sh <clustername> apply

          $ vault list -detailed yaook/<clustername>/k8s-pki/issuers
          Keys                                    is_default    issuer_name
          ----                                    ----------    -----------
          06a9511a-ffd2-2ce3-bd01-2cb2180a5e51    false         prev
          3e836f42-047f-b078-3795-0386aaff30c0    true          n/a
          $ vault list -detailed yaook/<clustername>/etcd-pki/issuers
          [...]
          $ vault list -detailed yaook/<clustername>/calico-pki/issuers
          [...]
          $ vault list -detailed yaook/<clustername>/k8s-front-proxy-pki/issuers
          [...]

      .. tab:: With intermediates

        .. code::

          $ ./managed-k8s/tools/vault/rotate-root-ca-intermediate.sh <clustername> apply

          $ vault list -detailed yaook/<clustername>/k8s-pki/issuers
          Keys                                    is_default    issuer_name
          ----                                    ----------    -----------
          06a9511a-ffd2-2ce3-bd01-2cb2180a5e51    false         prev
          3e836f42-047f-b078-3795-0386aaff30c0    true          n/a
          $ vault list -detailed yaook/<clustername>/etcd-pki/issuers
          [...]
          $ vault list -detailed yaook/<clustername>/calico-pki/issuers
          [...]
          $ vault list -detailed yaook/<clustername>/k8s-front-proxy-pki/issuers
          [...]

2. Complete the rotation by removing the old CA from accepted bundles
   and renewing certificates for all components

  .. code:: bash

    $ MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/rotate-ca.sh -c

3. Verify workload is able to come back up

4. Verify the logs of all Kubernetes components

5. Run the smoke tests

   .. code:: bash

     $ ./managed-k8s/actions/test.sh
