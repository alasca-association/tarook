HashiCorp Vault
===============

The ``vault_v1`` role deploys a HashiCorp Vault instance in the
Kubernetes cluster. This is not to be confused with (upcoming) support
for using HashiCorp Vault as a backend for storing LCM secrets.

For more details about the software, check out the
`HashiCorp Vault <https://www.vaultproject.io/>`__
website. The deployment happens
via the
`Vault Helm Chart <https://github.com/hashicorp/vault-helm/>`__.

.. note::
   
   The Vault integration is considered ready for production. It’s
   deployed in a highly available fashion (n=3) and comes with support for
   backups and monitoring. The initial unseal keys are written to the file
   system and must be **rotated as soon as possible and the fresh keys then
   stored appropriately**. Note that one can create a fresh root token as
   long as one has the necessary unseal key(s).

Backups
-------

Backups have become opt-out instead of opt-in because of their
importance. The role deploys the
`backup-creator and -shifter tandem <https://gitlab.com/yaook/images/backup-creator>`__
which pushes an encrypted snapshot to an S3 bucket.
If you want to use this built-in
backup mechanism (which you should unless you have an alternative),
create a copy of
``managed-k8s/templates/vault_backup_s3_config.template.yaml``, place it
as ``config/vault_backup_s3_config.yaml`` and fill in the gaps. Disable
backups by setting ``enable_backups = false``. Consider the
`official docs <https://developer.hashicorp.com/vault/tutorials/standard-procedures/sop-restore>`__
for restore instructions.

Credential management
---------------------

Unseal key(s) and an initial root token are cached in the cluster
repository (``inventory/.etc/vault_unseal.key`` and
``inventory/.etc/vault_root_token``). It is up to you to rotate and
store them securely. The role requires privileges to create certain
policies and approles so for now we rely on using a root token (which is
kind of ugly).

-  The root token is either read from the file system
   (``inventory/.etc/vault_root_token``) or from the environment
   variable ``VAULT_TOKEN``.
-  If vault is sealed, then the role will attempt to read the unseal
   keys from the file system (``inventory/.etc/vault_unseal.key``). If
   they cannot be found, ask the (human) operators to unlock vault for
   you.

Monitoring
----------

Vault offers metrics and the role deploys a corresponding service
monitor including required means of authentication and authorization. No
alerting rules have been defined yet but one probably wants to keep an
eye on vault’s performance, response error rate and seal status.

API endpoints and certificates
------------------------------

By default, vault listens on a cluster internal API endpoint whose
authenticity is ensured by a self-signed PKI. If you need to use that
endpoint you can find the certificate in the secret
``vault-ca-internal``. The LCM does **not** fetch the certificate for
you. Additionally, one can define external (or public) endpoints. Place
the DNS names in the ``dnsnames`` list and ensure that the records and
your ingress controller are properly configured. Furthermore you have to
specify a ``(Cluster)Issuer`` in ``external_ingress_issuer_name`` and,
if required, change the value of ``external_ingress_issuer_kind``.

Note: We cannot assume the existence of a publically available vault
endpoint but must be able to interact with the vault cluster from the
orchestrator. As a consequence we cannot make use of ansible’s built-in
vault modules but instead we have to jump into the vault pods to execute
commands as our second-best option.

Vault Configuraton
------------------

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: ksl_vault_configuration
   :end-before: # ANCHOR_END: ksl_vault_configuration