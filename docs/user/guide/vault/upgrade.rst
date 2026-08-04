Upgrading Hashicorp Vault
=========================

.. note::

   This guide refers to the Vault cluster that can be deployed with Tarook
   through :ref:`configuration-options.yk8s.k8s-service-layer.vault`,
   not the instance of Vault used by Tarook to store secrets.


Procedure
---------

Follow the instructions for "Upgrading Vault on Kubernetes"
in HashiCorp Vault's documentation:
https://developer.hashicorp.com/vault/docs/v1.19.x/deploy/kubernetes/helm/run#upgrading-vault-on-kubernetes.

**Additional notes**:

- For backing up Vault, do one of the following actions:

  - a) Configure automatic backups (recommended)

       See :doc:`/user/guide/vault/automatic-backups`

  - b) Create a Raft storage snapshot

       .. code:: shell

          vault operator raft snapshot save ./vault-raft-snapshot


       You may quickly verify that the snapshot is valid by running
       ``vault operator raft snapshot inspect ./vault-raft-snapshot``.

- Tarook uses Helm to deploy Vault.
  Instead of interacting with Helm directly, do the following:

  1. Set :ref:`configuration-options.yk8s.k8s-service-layer.vault.chart_version`
     to the new version of the Vault Helm chart you want to deploy

  2. Rollout the new version

     .. code:: shell

        tarook apply supplements install-vault.yaml


- Tarook configures the Vault Helm chart
  to deploy Vault in ``ha`` mode with 3 replicas,
  therefore follow the instructions specific to ``ha`` mode.

- Removing the standby peers from Raft before deleting their Pods
  is not strictly needed.

  If you still remove them,
  note that Vault does not support rejoining peers into the cluster.
  Instead, those need to be joined as *new* peers
  which can be done by deleting the corresponding PersistentVolumeClaims along with the Pods.
