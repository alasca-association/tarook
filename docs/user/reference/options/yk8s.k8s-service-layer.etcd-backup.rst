.. _configuration-options.yk8s.k8s-service-layer.etcd-backup:

yk8s.k8s-service-layer.etcd-backup
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Automated etcd backups can be configured in this section. When enabled
it periodically creates snapshots of etcd database and store it in a
object storage using s3. It uses the helm chart
`etcdbackup <https://gitlab.com/yaook/operator/-/tree/devel/yaook/helm_builder/Charts/etcd-backup>`__
present in yaook operator helm chart repository. The object storage
retains data for 30 days then deletes it.

The usage of it is disabled by default but can be enabled (and
configured) in the following section. The credentials are stored in
Vault. By default, they are searched for in the cluster’s kv storage (at
``yaook/$clustername/kv``) under ``etcdbackup``. They must be in the
form of a JSON object/dict with the keys ``access_key`` and
``secret_key``.

.. note::

  To enable etcd-backup,
  :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.enabled`
  needs to be set to ``true``.

The following values need to be set:

================== =======================================
Variable           Description
================== =======================================
``access_key``     Identifier for your S3 endpoint
``secret_key``     Credential for your S3 endpoint
``endpoint_url``   URL of your S3 endpoint
``endpoint_cacrt`` Certificate bundle of the endpoint.
================== =======================================

These must be put into a YAML file located at ``config/etcd_backup_s3_config.yaml``.
The configuration then can be imported to Vault by executing:

.. note::

  A root token is required.

.. code:: console

  $ ./managed-k8s/tools/vault/update.sh

Alternatively, you can also manually insert your configuration into vault.

.. raw:: html

  <details>
  <summary>etcd-backup configuration template</summary>

.. literalinclude:: /templates/etcd_backup_s3_config.template.yaml
  :language: yaml

.. raw:: html

  </details>

.. raw:: html

  <details>
  <summary>Generate/Figure out etcd-backup configuration values</summary>

.. code:: shell

  # Generate access and secret key on OpenStack
  openstack ec2 credentials create

  # Get certificate bundle of url
  openssl s_client -connect ENDPOINT_URL:PORT showcerts 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p'

.. raw:: html

  </details>

.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.bucket_name:

``yk8s.k8s-service-layer.etcd-backup.bucket_name``
##################################################

Name of the s3 bucket to store the backups.


**Type:**::

  non-empty string


**Default:**::

  "etcd-backup"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.chart_version:

``yk8s.k8s-service-layer.etcd-backup.chart_version``
####################################################

etcdbackup chart version to install.


**Type:**::

  non-empty string


**Default:**::

  "0.20250605.2"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.days_of_retention:

``yk8s.k8s-service-layer.etcd-backup.days_of_retention``
########################################################

Number of days after which individual items in the bucket are dropped. Enforced by S3 lifecyle rules which
are also implemented by Ceph's RGW.


**Type:**::

  signed integer


**Default:**::

  30


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.enabled:

``yk8s.k8s-service-layer.etcd-backup.enabled``
##############################################

Whether to enable etcd-backups.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.file_prefix:

``yk8s.k8s-service-layer.etcd-backup.file_prefix``
##################################################

Name of the folder to keep the backup files.


**Type:**::

  string


**Default:**::

  "etcd-backup"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm_repo_url:

``yk8s.k8s-service-layer.etcd-backup.helm_repo_url``
####################################################



**Type:**::

  non-empty string


**Default:**::

  "https://charts.yaook.cloud/operator/stable/"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.metrics_port:

``yk8s.k8s-service-layer.etcd-backup.metrics_port``
###################################################

Metrics port on which the backup-shifter Pod will provide metrics.
Please note that the etcd-backup deployment runs in host network mode
for easier access to the etcd cluster.


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  19100


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.name:

``yk8s.k8s-service-layer.etcd-backup.name``
###########################################



**Type:**::

  non-empty string


**Default:**::

  "etcd-backup"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.namespace:

``yk8s.k8s-service-layer.etcd-backup.namespace``
################################################



**Type:**::

  non-empty string


**Default:**::

  "kube-system"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.schedule:

``yk8s.k8s-service-layer.etcd-backup.schedule``
###############################################

Configure value for the cron job schedule for etcd backups.


**Type:**::

  non-empty string


**Default:**::

  "21 */12 * * *"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.secret_name:

``yk8s.k8s-service-layer.etcd-backup.secret_name``
##################################################



**Type:**::

  non-empty string


**Default:**::

  "etcd-backup-s3-credentials"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.vault_mount_point:

``yk8s.k8s-service-layer.etcd-backup.vault_mount_point``
########################################################

Configure the location of the Vault kv2 storage where the credentials can
be found. This location is the default location used by import.sh and is
recommended.


**Type:**::

  non-empty string


**Default:**::

  "yaook/\${config.yk8s.vault.cluster_name}/kv"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.vault_path:

``yk8s.k8s-service-layer.etcd-backup.vault_path``
#################################################

Configure the kv2 key under which the credentials are found inside Vault.
This location is the default location used by import.sh and is recommended.

The role expects a JSON object with `access_key` and `secret_key` keys,
containing the corresponding S3 credentials.


**Type:**::

  non-empty string


**Default:**::

  "etcdbackup"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix

