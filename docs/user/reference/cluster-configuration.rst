Cluster Configuration
=====================

The :doc:`environment variables </user/reference/environmental-variables>` affect the
:doc:`action scripts </user/reference/actions-references>`. The
``config/config.toml`` however is the main configuration file and can be
adjusted to customize the yk8s cluster to fit your needs. It also
contains operational flags which can trigger operational tasks. After
:doc:`initializing a cluster repository </user/guide/initialization>`, the
``config/config.toml`` contains necessary (default) values to create a
cluster. However, you’ll still need to adjust some of them before
triggering a cluster creation.

The ``config/config.toml`` configuration file
---------------------------------------------

The ``config.toml`` configuration file is created during the
:doc:`cluster repository initialization </user/guide/initialization>` from the
``templates/config.template.toml`` file. You can (and must) adjust some
of it’s values.

Before triggering an action script, the
:ref:`inventory updater <actions-references.update_inventorypy>`
automatically reads the configuration file, processes it, and puts
variables into the ``inventory/``. The ``inventory/`` is automatically
included. Following the concept of separation of concerns, variables are
only available to stages/layers which need them.

Configuring Terraform
~~~~~~~~~~~~~~~~~~~~~

You can overwrite all Terraform related variables (see below for
where to find a complete list) in the Terraform section of your ``config.toml``.

By default 3 control plane nodes and 4 workers will get created. You’ll
need to adjust these values if you e.g. want to enable
:doc:`rook </user/explanation/services/rook-storage>`.

.. note::

   Right now there is a variable ``masters`` to configure the k8s
   controller server count and ``workers`` for the k8s node count. However
   there is no explicit variable for the gateway node count! This is
   implicitly defined by the number of elements in the ``azs`` array.

Please not that with the introduction of ``for_each`` in our terraform
module, you can delete individual nodes. Consider the following example:

.. code:: toml

   [terraform]
   workers = 3
   worker_names = ["0", "1", "2"]

In order to delete any of the nodes, decrease the ``workers`` count and
remove the suffix of the worker from the list. After removing, i.e.,
“1”, your config would look like this:

.. code:: toml

   [terraform]
   workers = 2
   worker_names = ["0", "2"]

For an auto-generated complete list of variables, please refer to
:doc:`Terraform docs </developer/reference/terraform-docs>`.

To activate automatic backend of Terraform statefiles to Gitlab,
adapt the Terraform section of your ``config.toml``:
set `gitlab_backend` to True,
set the URL of the Gitlab project and
the name of the Gitlab state object.

.. code:: toml

   [terraform]
   gitlab_backend    = true
   gitlab_base_url   = "https://gitlab.com"
   gitlab_project_id = "012345678"
   gitlab_state_name = "tf-state"

Put your Gitlab username and access token
into the ``~/.config/yaook-k8s/env``.
Your Gitlab access token must have
at least Maintainer role and
read/write access to the API.
Please see GitLab documentation for creating a
`personal access token <https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html>`__.

To successful migrate from the "local" to "http" Terraform backend method,
ensure that `gitlab_backend` is set to `true`
and all other required variables are set correctly.
Incorrect data entry may result in an HTTP error respond,
such as a HTTP/401 error for incorrect credentials.
Assuming correct credentials in the case of an HTTP/404 error,
Terraform is executed and the state is migrated to Gitlab.

To migrate from the "http" to "local" Terraform backend method,
set `gitlab_backend=false`,
`MANAGED_K8S_NUKE_FROM_ORBIT=true`,
and assume
that all variables above are properly set
and the Terraform state exists on GitLab.
Once the migration is successful,
unset the variables above
to continue using the "local" backend method.

.. code:: toml

   export TF_HTTP_USERNAME="<gitlab-username>"
   export TF_HTTP_PASSWORD="<gitlab-access-token>"

Excerpt from ``templates/config.template-toml``:

.. raw:: html

   <details>
   <summary>config.toml: Terraform configuration</summary>


.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: terraform_config
   :end-before: # ANCHOR_END: terraform_config

.. raw:: html

   </details>

|

.. _cluster-configuration.configuring-load-balancing:

Configuring Load-Balancing
~~~~~~~~~~~~~~~~~~~~~~~~~~

By default, if you’re deploying on top of OpenStack, the self-developed
load-balancing solution :doc:`ch-k8s-lbaas </user/explanation/services/ch-k8s-lbaas>`
will be used to avoid the aches of using OpenStack Octavia. Nonetheless,
you are not forced to use it and can easily disable it.

The following section contains legacy load-balancing options which will
probably be removed in the foreseeable future.

.. raw:: html

   <details>
   <summary>config.toml: Historic load-balancing configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: load-balancing_config
   :end-before: # ANCHOR_END: load-balancing_config

.. raw:: html

   </details>

|

Kubernetes Cluster Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This section contains generic information about the Kubernetes cluster
configuration.

Basic Cluster Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. raw:: html

   <details>
   <summary>config.toml: Kubernetes basic cluster configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: kubernetes_basic_cluster_configuration
   :end-before: # ANCHOR_END: kubernetes_basic_cluster_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.calico-configuration:

Calico Configuration
^^^^^^^^^^^^^^^^^^^^

The following configuration options are specific to calico, our CNI
plugin in use.

.. raw:: html

   <details>
   <summary>config.toml: Kubernetes basic cluster configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: calico_configuration
   :end-before: # ANCHOR_END: calico_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.storage-configuration:

Storage Configuration
^^^^^^^^^^^^^^^^^^^^^

.. raw:: html

   <details>
   <summary>config.toml: Kubernetes - Basic Storage Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: storage_base_configuration
   :end-before: # ANCHOR_END: storage_base_configuration

.. raw:: html

   </details>


.. raw:: html

   <details>
   <summary>config.toml: Kubernetes - Static Local Storage Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: storage_local_static_configuration
   :end-before: # ANCHOR_END: storage_local_static_configuration

.. raw:: html

   </details>

.. raw:: html

   <details>
   <summary>config.toml: Kubernetes - Dynamic Local Storage Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: storage_local_dynamic_configuration
   :end-before: # ANCHOR_END: storage_local_dynamic_configuration

.. raw:: html

   </details>

|

Monitoring Configuration
^^^^^^^^^^^^^^^^^^^^^^^^

.. raw:: html

   <details>
   <summary>config.toml: Kubernetes - Monitoring Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: kubernetes_monitoring_configuration
   :end-before: # ANCHOR_END: kubernetes_monitoring_configuration

.. raw:: html

   </details>

|

Global Monitoring Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

It is possible to connect the monitoring stack of your yk8s-cluster to
an external endpoint like e.g. a monitoring-cluster. The following
section can be used to enable and configure that.

.. note::

   This requires changes and therefore the (re-)appliance of
   all layers.

.. raw:: html

   <details>
   <summary>config.toml: Kubernetes - Global Monitoring Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: kubernetes_global_monitoring_configuration
   :end-before: # ANCHOR_END: kubernetes_global_monitoring_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.network-configuration:

Network Configuration
^^^^^^^^^^^^^^^^^^^^^

.. note::

   To enable the calico network plugin,
   ``kubernetes.network.plugin`` needs to be set to ``calico``.

.. raw:: html

   <details>
   <summary>config.toml: Kubernetes - Network Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: kubernetes_network_configuration
   :end-before: # ANCHOR_END: kubernetes_network_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.kubelet-configuration:

kubelet Configuration
^^^^^^^^^^^^^^^^^^^^^

The LCM supports the customization of certain variables of ``kubelet``
for (meta-)worker nodes.

.. note::

   Applying changes requires to enable
   :ref:`disruptive actions <environmental-variables.behavior-altering-variables>`.

.. raw:: html

   <details>
   <summary>config.toml: Kubernetes - kubelet Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: kubernetes_kubelet_configuration
   :end-before: # ANCHOR_END: kubernetes_kubelet_configuration

.. raw:: html

   </details>

|

KSL - Kubernetes Service Layer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _cluster-configuration.rook-configuration:

Rook Configuration
^^^^^^^^^^^^^^^^^^

The used rook setup is explained in more detail
:doc:`here </user/explanation/services/rook-storage>`.

.. note::

   To enable rook in a cluster on top of OpenStack, you need
   to set both ``k8s-service-layer.rook.nosds`` and
   ``k8s-service-layer.rook.osd_volume_size``, as well as enable
   ``kubernetes.storage.rook_enabled`` and either
   ``kubernetes.local_storage.dynamic.enabled`` or
   ``kubernetes.local_storage.static.enabled`` local
   storage (or both) (see :ref:`storage configuration <cluster-configuration.storage-configuration>`).

.. raw:: html

   <details>
   <summary>config.toml: KSL - Rook Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: ksl_rook_configuration
   :end-before: # ANCHOR_END: ksl_rook_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.prometheus-configuration:

Prometheus-based Monitoring Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The used prometheus-based monitoring setup will be explained in more
detail soon :)

.. note::

   To enable prometheus,
   ``k8s-serice-layer.prometheus.install`` and
   ``kubernetes.monitoring.enabled`` need to be set to ``true``.

.. raw:: html

   <details>
   <summary>config.toml: KSL - Prometheus Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: ksl_prometheus_configuration
   :end-before: # ANCHOR_END: ksl_prometheus_configuration

.. raw:: html

   </details>

|

Tweak Thanos Configuration
""""""""""""""""""""""""""

index-cache-size / in-memory-max-size
*************************************

Thanos is unaware of its Kubernetes limits
which can lead to OOM kills of the storegateway
if a lot of metrics are requested.

We therefore added an option to configure the
``index-cache-size``
(see `Tweak Thanos configuration (!1116) · Merge requests · YAOOK / k8s · GitLab <https://gitlab.com/yaook/k8s/-/merge_requests/1116/diffs>`__
and (see `Thanos - Highly available Prometheus setup with long term storage capabilities <https://thanos.io/tip/components/store.md/#in-memory-index-cache>`__)
which should prevent that and is available as of `release/v3.0 · YAOOK / k8s · GitLab <https://gitlab.com/yaook/k8s/-/blob/release/v3.0/CHANGELOG.rst>`__.

It can be configured by setting
the following in the clusters ``config/config.toml``:

.. code:: toml

   # [...]
   [k8s-service-layer.prometheus]
   # [...]
   thanos_store_in_memory_max_size = "XGB"
   thanos_store_memory_request = "XGi"
   thanos_store_memory_limit = "XGi"
   # [...]

Note that the value must be a decimal unit!
Please also note that you should set a meaningful value
based on the configured ``thanos_store_memory_limit``.
If this variable is not explicitly configured,
the helm chart default is used which is not optimal.
You should configure both variables and in the best
case you additionally set ``thanos_store_memory_request``
to the same value as ``thanos_store_memory_limit``.

Persistence
***********

With `release/v3.0 · YAOOK / k8s · GitLab <https://gitlab.com/yaook/k8s/-/blob/release/v3.0/CHANGELOG.rst>`__,
persistence for Thanos components has been reworked.
By default, Thanos components use emptyDirs.
Depending on the size of the cluster and the metrics
flying around, Thanos components may need more disk
than the host node can provide them and in that cases
it makes sense to configure persistence.

If you want to enable persistence for Thanos components,
you can do so by configuring a storage class
to use and you can specify the persistent volume
size for each component like in the following.

.. code:: toml

   # [...]
   [k8s-service-layer.prometheus]
   # [...]
   thanos_storage_class = "SOME_STORAGE_CLASS"
   thanos_storegateway_size = "XGi"
   thanos_compactor_size = "YGi"
   thanos_query_size = "ZGi"
   # [...]

|

.. _cluster-configuration.nginx-ingress-configuration:

NGINX Ingress Controller Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The used NGINX ingress controller setup will be explained in more detail
soon :)

.. note::

   To enable an ingress controller,
   ``k8s-service-layer.ingress.enabled`` needs to be set to ``true``.

.. raw:: html

   <details>
   <summary>config.toml: KSL - NGINX Ingress Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: ksl_ingress_configuration
   :end-before: # ANCHOR_END: ksl_ingress_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.cert-manager-configuration:

Cert-Manager Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^

The used Cert-Manager controller setup will be explained in more detail
soon :)

   .. note::

      To enable cert-manager,
      ``k8s-service-layer.cert-manager.enabled`` needs to be set to
      ``true``.

.. raw:: html

   <details>
   <summary>config.toml: KSL - Cert-Manager Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: ksl_cert_manager_configuration
   :end-before: # ANCHOR_END: ksl_cert_manager_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.etcd-backup-configuration:

etcd-backup Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^

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
   ``k8s-service-layer.etcd-backup.enabled`` needs to be set to
   ``true``.

.. raw:: html

   <details>
   <summary>config.toml: KSL - Etcd-backup Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: etcd_backup_configuration
   :end-before: # ANCHOR_END: etcd_backup_configuration

.. raw:: html

   </details>

|

The following values need to be set:

================== =======================================
Variable           Description
================== =======================================
``access_key``     Identifier for your S3 endpoint
``secret_key``     Credential for your S3 endpoint
``endpoint_url``   URL of your S3 endpoint
``endpoint_cacrt`` Certificate bundle of the endpoint.
================== =======================================

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

|

.. _cluster-configuration.flux:

Flux
~~~~~~~

More details about our FluxCD2 implementation can be found
:doc:`here </user/explanation/services/fluxcd>`.

The following configuration options are available:

.. raw:: html

   <details>
   <summary>config.toml: KSL - Flux</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: ksl_fluxcd_configuration
   :end-before: # ANCHOR_END: ksl_fluxcd_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.node-scheduling-labels-taints-configuration:

Node-Scheduling: Labels and Taints Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. note::
   Nodes get their labels and taints during the Kubernetes
   cluster initialization and node-join process.
   Once a node has joined the cluster,
   its labels and taints will **not** get updated anymore.

More details about the labels and taints configuration can be found
:doc:`here </user/explanation/node-scheduling>`.

.. raw:: html

   <details>
   <summary>config.toml: Node-Scheduling: Labels and Taints Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: node_scheduling_configuration
   :end-before: # ANCHOR_END: node_scheduling_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.wireguard-configuration:

Wireguard Configuration
~~~~~~~~~~~~~~~~~~~~~~~

You **MUST** add yourself to the :doc:`wireguard </user/explanation/vpn/wireguard>`
peers.

You can do so either in the following section of the config file or by
using and configuring a git submodule. This submodule would then refer
to another repository, holding the wireguard public keys of everybody
that should have access to the cluster by default. This is the
recommended approach for companies and organizations.

.. raw:: html

   <details>
   <summary>config.toml: Wireguard Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: wireguard_config
   :end-before: # ANCHOR_END: wireguard_config

.. raw:: html

   </details>

|

IPsec Configuration
~~~~~~~~~~~~~~~~~~~

More details about the IPsec setup can be found
:doc:`here </user/explanation/vpn/ipsec>`.

.. raw:: html

   <details>
   <summary>config.toml: IPsec Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: ipsec_configuration
   :end-before: # ANCHOR_END: ipsec_configuration

.. raw:: html

   </details>

|

Testing
~~~~~~~

Testing Nodes
^^^^^^^^^^^^^

The following configuration section can be used to ensure that smoke
tests and checks are executed from different nodes. This is disabled by
default as it requires some prethinking.

.. raw:: html

   <details>
   <summary>config.toml: Testing Nodes Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: testing_test_nodes_configuration
   :end-before: # ANCHOR_END: testing_test_nodes_configuration

.. raw:: html

   </details>

|

Custom Configuration
--------------------

Since yaook/k8s allows to
:ref:`execute custom playbook(s) <abstraction-layers.customization>`, the
following section allows you to specify your own custom variables to be
used in these.

.. raw:: html

   <details>
   <summary>config.toml: Custom Configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: custom_configuration
   :end-before: # ANCHOR_END: custom_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.miscellaneous-configuration:

Miscellaneous Configuration
---------------------------

This section contains various configuration options for special use
cases. You won’t need to enable and adjust any of these under normal
circumstances.

.. raw:: html

   <details>
   <summary>Miscellaneous configuration</summary>

.. literalinclude:: /templates/config.template.toml
   :language: toml
   :start-after: # ANCHOR: miscellaneous_configuration
   :end-before: # ANCHOR_END: miscellaneous_configuration

.. raw:: html

   </details>

|

.. _cluster-configuration.ansible-configuration:

Ansible Configuration
---------------------

The Ansible configuration file can be found in the ``ansible/``
directory. It is used across all stages and layers.

.. raw:: html

   <details>
   <summary>Default Ansible configuration</summary>

.. literalinclude:: /templates/ansible.cfg
   :language: ini

.. raw:: html

   </details>
