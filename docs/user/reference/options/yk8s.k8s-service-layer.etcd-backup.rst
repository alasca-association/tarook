.. _configuration-options.yk8s.k8s-service-layer.etcd-backup:

yk8s.k8s-service-layer.etcd-backup
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Automated etcd backups can be configured in this section. When enabled,
it periodically creates snapshots of etcd database and stores them in an
object storage bucket using S3. It uses the helm chart
`etcdbackup <https://gitlab.com/yaook/operator/-/tree/devel/yaook/helm_builder/Charts/etcd-backup>`__
present in yaook operator helm chart repository.

The usage of it is disabled by default, but can be enabled (and
configured) in the following section. The credentials are stored in
Vault. By default, they are searched for in the cluster’s kv storage (at
``yaook/$clustername/kv``) under ``etcdbackup``. They must be in the
form of a JSON object/dict with the keys ``access_key`` and
``secret_key``.

The following values need to be set:

================== =======================================
Variable           Description
================== =======================================
``access_key``     Identifier for your S3 endpoint
``secret_key``     Credential for your S3 endpoint
``endpoint_url``   URL of your S3 endpoint
``certRef``        CA certificate bundle for validation of the endpoint's certificate
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

.. important::

  The bucket configured in
  :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.bucket`
  is expected to exist and must be created manually in advance!

.. raw:: html

  <details>
  <summary>OpenStack: Generate EC2 credentials</summary>

.. code:: shell

  # Generate access and secret key on OpenStack
  openstack ec2 credentials create

.. raw:: html

  </details>

.. raw:: html

  <details>
  <summary>OpenStack: Generate object storage container (bucket)</summary>

.. code:: shell

  # Generate object storage container on OpenStack
  containername="$(yq --raw-output '.etcd_backup_helm_values.targets.s3.bucket' inventory/yaook-k8s/group_vars/all/etcd-backup.yaml)"
  openstack container create "$containername"

.. raw:: html

  </details>

.. raw:: html

  <details>
  <summary>Get certificate chain of S3 endpoint</summary>

.. code:: shell

  # Get certificate bundle of url
  openssl s_client -connect ENDPOINT_URL:PORT showcerts 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p'

.. raw:: html

  </details>

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
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.chart_ref:

``yk8s.k8s-service-layer.etcd-backup.helm.chart_ref``
#####################################################

The chart reference (relative to the repository) of the etcd-backup Helm chart.


**Type:**::

  RFC3986 relative URL path or RFC3986 URL


**Default:**::

  "etcdbackup"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.chart_repo_url:

``yk8s.k8s-service-layer.etcd-backup.helm.chart_repo_url``
##########################################################

The URL to the Helm repository for the etcd-backup Helm chart.


**Type:**::

  null or RFC3986 URL


**Default:**::

  "https://charts.yaook.cloud/operator/stable/"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.chart_version:

``yk8s.k8s-service-layer.etcd-backup.helm.chart_version``
#########################################################

Version of the etcd-backup Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "2.4.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.release_name:

``yk8s.k8s-service-layer.etcd-backup.helm.release_name``
########################################################

The release name inside the cluster for etcd-backup.


**Type:**::

  non-empty string


**Default:**::

  "etcd-backup"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.release_namespace:

``yk8s.k8s-service-layer.etcd-backup.helm.release_namespace``
#############################################################

The namespace in which to install etcd-backup.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "kube-system"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values:

``yk8s.k8s-service-layer.etcd-backup.helm.values``
##################################################

Helm values for the etcd-backup helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://gitlab.com/yaook/operator/-/blob/devel/yaook/helm_builder/Charts/etcdbackup/values-template.yaml.j2


**Type:**::

  open submodule of (attribute set containing JSON compatible values)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.certRef:

``yk8s.k8s-service-layer.etcd-backup.helm.values.certRef``
##########################################################

Can not be set here and will be supplied dynamically via Ansible
See :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup` for how to set the value.


**Type:**::

  unspecified value


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.metrics_port:

``yk8s.k8s-service-layer.etcd-backup.helm.values.metrics_port``
###############################################################

Metrics port on which the backup-shifter Pod will provide metrics.
Please note that the etcd-backup deployment runs in host network mode
for easier access to the etcd cluster.


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  19100


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.schedule:

``yk8s.k8s-service-layer.etcd-backup.helm.values.schedule``
###########################################################

Configure value for the cron job schedule for etcd backups.


**Type:**::

  non-empty string


**Default:**::

  "21 */12 * * *"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.addressingStyle:

``yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.addressingStyle``
#############################################################################

The addressing style used for the s3 bucket that stores the etcd backups.

- ``path``: Bucket name is included in the URI path.
- ``virtual``: Bucket name is included in the hostname.
- ``auto``: Attempts to use virtual, but falls back to path if necessary.


**Type:**::

  one of "path", "virtual", "auto"


**Default:**::

  "path"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.bucket:

``yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.bucket``
####################################################################

Name of the s3 bucket to store the backups.

The bucket is expected to exist and must be created manually in advance!


**Type:**::

  S3 bucket name


**Default:**::

  "etcd-backup"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.credentialRef.name:

``yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.credentialRef.name``
################################################################################



**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "etcd-backup-s3-credentials"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.endpoint:

``yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.endpoint``
######################################################################

Can not be set here and will be supplied dynamically via Ansible.
See :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup` for how to set the value.


**Type:**::

  unspecified value


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.filePrefix:

``yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.filePrefix``
########################################################################

Prefix for :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.bucket`


**Type:**::

  S3 bucket name prefix


**Default:**::

  "etcd-backup"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.vault_mount_point:

``yk8s.k8s-service-layer.etcd-backup.vault_mount_point``
########################################################

Configure the location of the Vault kv2 storage where the credentials can
be found. This location is the default location used by import.sh and is
recommended.


**Type:**::

  Name of a Hashicorp Vault namespace


**Default:**::

  "yaook/${config.yk8s.vault.cluster_name}/kv"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix


.. _configuration-options.yk8s.k8s-service-layer.etcd-backup.vault_path:

``yk8s.k8s-service-layer.etcd-backup.vault_path``
#################################################

Configure the kv2 key under which the credentials are found inside Vault.
This location is the default location used by import.sh and is recommended.

The role expects a JSON object with `access_key` and `secret_key` keys,
containing the corresponding S3 credentials.


**Type:**::

  RFC3986 relative URL path


**Default:**::

  "etcdbackup"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/etcd-backup.nix

