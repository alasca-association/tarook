Automatic backups of HashiCorp Vault
====================================

.. note::

   This guide refers to the Vault cluster that can be deployed with Tarook
   through :ref:`configuration-options.yk8s.k8s-service-layer.vault`.

   The instance of Vault used by Tarook to store secrets
   will be referred to as "secrets backend".


Tarook uses the |vaultbackup|_ Helm chart maintained by Yaook
for periodically backing up HashiCorp Vault to a S3 bucket.

.. |vaultbackup| replace:: ``vaultbackup``
.. _vaultbackup: https://gitlab.com/yaook/operator/-/tree/devel/yaook/helm_builder/Charts/vaultbackup

Automatic backups of HashiCorp Vault can be enabled
with the :ref:`configuration-options.yk8s.k8s-service-layer.vault.enable_backups`
configuration option.
Location of and credentials for the S3 bucket must be provided
through :ref:`configuration-options.yk8s.k8s-service-layer.vault.backup_s3_bucket`
and :ref:`configuration-options.yk8s.k8s-service-layer.vault.s3_config_file`.

Prerequisites
-------------

- :ref:`configuration-options.yk8s.k8s-service-layer.vault.enabled` set to ``true``
- A S3 bucket that is accessible from within your cluster
  and the credentials for uploading files to that bucket
- A Vault root token for storing the bucket credentials in Tarook's secrets backend

Setup steps
-----------

1. Enable automatic backups in Tarook's configuration

   Set :ref:`configuration-options.yk8s.k8s-service-layer.vault.enable_backups`
   to ``true``

2. Configure the bucket location and credentials in a file
   and upload it to the secrets backend

   1. Set :ref:`configuration-options.yk8s.k8s-service-layer.vault.s3_config_file`
      and create that file relative to ``./config/`` in your cluster repository.

      See the description of the config option for details on file format and content.

   2. Upload to the secrets backend

      .. code:: console

         $ VAULT_TOKEN=${vault_root_token:?} managed-k8s/tools/vault/update.sh
         ..........
         -----------------------------------------------
         Trying to import Vault backup config ...
         ..........
         Successfully imported Vault S3 object storage configuration into Vault.
         Removing Vault S3 backup config/vault-backup-bucket.yaml
         -----------------------------------------------
         ..........
         $


   3. Unset :ref:`configuration-options.yk8s.k8s-service-layer.vault.s3_config_file`

3. Set :ref:`configuration-options.yk8s.k8s-service-layer.vault.backup_s3_bucket`
   to your bucket's name
   (``vault-backup`` by default)

4. Rollout the configuration

   .. code:: shell

      VAULT_TOKEN=${vault_orchestrator_token:?} \
        ./managed-k8s/actions/apply-k8s-supplements.sh install-vault.yaml


5. Verify backups are working

   1. Trigger a backup run

      Run ``backup-now`` in the ``backup-creator`` container of the vault-backup Pod.

      .. code:: console

         $ vault_namespace="$( \
         >   ansible-inventory -i inventory/yaook-k8s/ --list --export \
         >   | jq --raw-output .all.vars.yaook_vault_namespace \
         > )"
         $ vault_backup_pod="$( \
         >   kubectl get pods \
         >     --namespace="${vault_namespace:?}" \
         >     --selector=yaook.cloud/component=vault-backup \
         >     --output=name \
         >   | head -1 \
         > )"
         $ kubectl exec \
         >   --namespace="${vault_namespace:?}" \
         >   "${vault_backup_pod:?}" \
         >   --container=backup-creator \
         >   -- backup-now
         ..........
         2026-03-19 14:32:09,310 - backup_creator - INFO - Running backup job
         ..........
         2026-03-19 14:32:09,657 - backup_creator - INFO - Backup finished
         ..........
         $


   2. Verify that backups are uploaded to the S3 bucket

      Watch the logs of the ``backup-shifter`` container of the vault-backup Pod.
      New backups are uploaded automatically.

      .. code:: console

         $ kubectl logs \
         >   --namespace="${vault_namespace:?}" \
         >   "${vault_backup_pod:?}" \
         >   --container=backup-shifter \
         >   --timestamps=true \
         >   --since=5m
         ..........
         2026-03-19T14:32:10.476553346Z INFO:root:Upload successfull
         ..........

   3. Test your restore procedure
