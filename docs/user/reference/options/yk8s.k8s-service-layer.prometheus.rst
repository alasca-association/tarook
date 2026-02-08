.. _configuration-options.yk8s.k8s-service-layer.prometheus:

yk8s.k8s-service-layer.prometheus
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


The used prometheus-based monitoring setup will be explained in more
detail soon :)

.. note::

  To enable prometheus,
  :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.install`
  and
  :ref:`configuration-options.yk8s.kubernetes.monitoring.enabled`
  need to be set to ``true``.


Tweak Thanos Configuration
""""""""""""""""""""""""""

index-cache-size / in-memory-max-size
*************************************

Thanos is unaware of its Kubernetes limits
which can lead to OOM kills of the storegateway
if a lot of metrics are requested.

This can be prevented by tuning the following config options:

  - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_in_memory_max_size`
  - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.memory`
  - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.requests.memory`

Note that the value must be a decimal unit!
Please also note that
if no explicit memory limit is configured
the helm chart default is used which is not optimal.
You should configure both memory limit and request
which are recommended to have the same value.

Persistence
***********

With `release/v3.0 · Tarook · GitLab <https://gitlab.com/alasca.cloud/tarook/tarook/-/blob/release/v3.0/CHANGELOG.rst>`__,
persistence for Thanos components has been reworked.
By default, Thanos components use emptyDirs.
Depending on the size of the cluster and the metrics
flying around, Thanos components may need more disk
than the host node can provide them and in that cases
it makes sense to configure persistence.

If you want to enable persistence for Thanos components,
you can do so by configuring a storage class
to use and you can specify the persistent volume
size for each component with the following config options:

  - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storage_class`
  - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storegateway_size`
  - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compactor_size`

.. _cluster-configuration.prometheus-configuration.updating-immutable-options:

Updating immutable options
**************************

Some options are immutable when deployed.
If you want to change them nonetheless, follow these manual steps:
1. Increase the size of the corresponding PVC
2. Delete the stateful set: ``kubectl delete -n monitoring sts --cascade=false thanos-<storegateway|compactor>``
3. Re-deploy it with the LCM: ``AFLAGS="--diff --tags thanos" bash managed-k8s/actions/apply-k8s-supplements.sh``

.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_replicas:

``yk8s.k8s-service-layer.prometheus.alertmanager_replicas``
###########################################################

How many replicas of the alertmanager should be deployed inside the cluster


**Type:**::

  unsigned integer, meaning >=0


**Default:**::

  1


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_resources:

``yk8s.k8s-service-layer.prometheus.alertmanager_resources``
############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.alertmanager_resources.limits.cpu``
#######################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.alertmanager_resources.limits.memory``
##########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "256Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.alertmanager_resources.requests.cpu``
#########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.alertmanager_resources.requests.memory``
############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.alertmanager_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.allow_external_rules:

``yk8s.k8s-service-layer.prometheus.allow_external_rules``
##########################################################

Whether to enable external rules.
By default, prometheus and alertmanager only consider global rules from the monitoring
namespace while other rules can only alert on their own namespace. If this variable is
set, cluster wide rules are considered from all namespaces.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.blackbox_version:

``yk8s.k8s-service-layer.prometheus.blackbox_version``
######################################################

Version of the Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "11.8.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.common_labels:

``yk8s.k8s-service-layer.prometheus.common_labels``
###################################################

If at least one common_label is defined, Prometheus will be created with selectors
matching these labels and only ServiceMonitors that meet the criteria of the selector,
i.e. are labeled accordingly, are included by Prometheus.
The LCM takes care that all ServiceMonitors created by itself are labeled accordingly.
The key can not be "release" as that one is already used by the Prometheus helm chart.


**Type:**::

  attribute set of Kubernetes label-value pairs


**Default:**::

  { }


**Example:**::

  {
    managed-by = "yaook-k8s";
  }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_admin_secret_name:

``yk8s.k8s-service-layer.prometheus.grafana_admin_secret_name``
###############################################################



**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "cah-grafana-admin"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_dashboard_enable_multicluster_support:

``yk8s.k8s-service-layer.prometheus.grafana_dashboard_enable_multicluster_support``
###################################################################################

Whether to enable referencing multiple K8s clusters by a single Grafana datasource.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_persistent_storage_class:

``yk8s.k8s-service-layer.prometheus.grafana_persistent_storage_class``
######################################################################

If this variable is defined, Grafana will store its data in a PersistentVolume
in the defined StorageClass. Otherwise, persistence is disabled for Grafana.
The value has to be a valid StorageClass available in your cluster.


**Type:**::

  null or RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_resources:

``yk8s.k8s-service-layer.prometheus.grafana_resources``
#######################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.grafana_resources.limits.cpu``
##################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.grafana_resources.limits.memory``
#####################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "512Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.grafana_resources.requests.cpu``
####################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  "500m"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.grafana_resources.requests.memory``
#######################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.grafana_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_root_url:

``yk8s.k8s-service-layer.prometheus.grafana_root_url``
######################################################

The full public facing url you use in browser, used for redirects and emails


**Type:**::

  null or RFC3986 HTTP(S) URL (scheme, authority and path only)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.install:

``yk8s.k8s-service-layer.prometheus.install``
#############################################

If :ref:`configuration-options.yk8s.kubernetes.monitoring.enabled` is ``true``, choose whether to install or uninstall
Prometheus. IF SET TO FALSE, PROMETHEUS WILL BE DELETED WITHOUT CHECKING FOR
DISRUPTION (sic!).


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe:

``yk8s.k8s-service-layer.prometheus.internet_probe``
####################################################

Whether to enable scraping external targets via blackbox exporter
https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets``
############################################################



**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.interval:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.interval``
#######################################################################

Scraping interval. Overrides value set in `defaults`


**Type:**::

  Prometheus interval string


**Default:**::

  "60s"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module``
#####################################################################

The module to be used for the probe.

Defaults to ``http_2xx`` if :ref:`configuration-options.yk8s.infra.ipv4_enabled` is ``true``.
Otherwise, defaults to ``http_2xx_v6`` if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is ``true``.

Modules without the ``_v6`` suffix use IPv4 as preferred protocol.
IPv6-specific modules (indicated by the ``_v6`` suffix) are only available
if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is enabled.
They use IPv6 as preferred protocol.

For example, if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is enabled,
you could use the module ``http_api_v6`` to probe the target
which allows HTTP status codes 200, 300, 400 and 401.


**Type:**::

  one of "http_2xx", "http_api", "http_api_insecure", "icmp", "tcp_connect", "http_2xx_v6", "http_api_v6", "http_api_insecure_v6", "icmp_v6", "tcp_connect_v6"


**Default:**::

  "http_2xx"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.name:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.name``
###################################################################

Pretty name that will appear in Prometheus / AlertManager


**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.scrapeTimeout:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.scrapeTimeout``
############################################################################

Scrape timeout. Overrides value set in `defaults`


**Type:**::

  Prometheus timeout string


**Default:**::

  "60s"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.url:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.url``
##################################################################

The URL that blackbox will scrape

Depending on
:ref:`configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module`
this needs to be a
HTTP URL (http_*),
IP address (icmp)
or IP address with port (tcp_connect).


**Type:**::

  RFC3986 HTTP(S) URL or IPv4 address in four-octets decimal notation or IPv6 address in colon-hexadecimal notation or IPv4 address in four-octets decimal notation with port or IPv6 address in colon-hexadecimal notation with port


**Example:**::

  "http://example.com/healthz"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources:

``yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources``
##################################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.limits.cpu``
#############################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.limits.memory``
################################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "128Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.requests.cpu``
###############################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "50m"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.requests.memory``
##################################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.manage_thanos_bucket:

``yk8s.k8s-service-layer.prometheus.manage_thanos_bucket``
##########################################################

Let terraform create an object storage container / bucket for you if `true`.
If set to `false` one must provide a valid configuration via Vault.
See :ref:`thanos.custom-bucket-management` for details.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.monitoring_internet_probe:

``yk8s.k8s-service-layer.prometheus.monitoring_internet_probe``
###############################################################

Whether to enable adding blackbox-exporter to test basic internet connectivity
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.namespace:

``yk8s.k8s-service-layer.prometheus.namespace``
###############################################

Namespace to deploy the monitoring in (will be created if it does not exist, but
never deleted).


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "monitoring"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.node_exporter_textfile_collector_path:

``yk8s.k8s-service-layer.prometheus.node_exporter_textfile_collector_path``
###########################################################################



**Type:**::

  Absolute POSIX path (without special '.' and '..')


**Default:**::

  "/var/lib/node_exporter/textfile_collector"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_repo_url:

``yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_repo_url``
########################################################################



**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://nvidia.github.io/dcgm-exporter/helm-charts"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_version:

``yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_version``
#######################################################################

Version of the Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "4.6.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources:

``yk8s.k8s-service-layer.prometheus.operator_resources``
########################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.operator_resources.limits.cpu``
###################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.operator_resources.limits.memory``
######################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "400Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.operator_resources.requests.cpu``
#####################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.operator_resources.requests.memory``
########################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.operator_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_adapter_release_name:

``yk8s.k8s-service-layer.prometheus.prometheus_adapter_release_name``
#####################################################################



**Type:**::

  Helm chart release name


**Default:**::

  "prometheus-adapter"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_adapter_version:

``yk8s.k8s-service-layer.prometheus.prometheus_adapter_version``
################################################################

Version of the Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "5.2.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_helm_repo_url:

``yk8s.k8s-service-layer.prometheus.prometheus_helm_repo_url``
##############################################################



**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://prometheus-community.github.io/helm-charts"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_persistent_storage_class:

``yk8s.k8s-service-layer.prometheus.prometheus_persistent_storage_class``
#########################################################################

Configure persistent storage for Prometheus
By default an empty-dir is used.
https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md


**Type:**::

  null or RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_persistent_storage_resource_request:

``yk8s.k8s-service-layer.prometheus.prometheus_persistent_storage_resource_request``
####################################################################################

Configure persistent storage for Prometheus
https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md


**Type:**::

  Kubernetes quantity


**Default:**::

  "50Gi"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources:

``yk8s.k8s-service-layer.prometheus.prometheus_resources``
##########################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.prometheus_resources.limits.cpu``
#####################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.prometheus_resources.limits.memory``
########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "3Gi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.prometheus_resources.requests.cpu``
#######################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "1"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.prometheus_resources.requests.memory``
##########################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.prometheus_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_service_name:

``yk8s.k8s-service-layer.prometheus.prometheus_service_name``
#############################################################



**Type:**::

  RFC1035 subdomain label (lowercase)


**Default:**::

  "prometheus-operated"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_stack_chart_name:

``yk8s.k8s-service-layer.prometheus.prometheus_stack_chart_name``
#################################################################



**Type:**::

  RFC3986 relative URL path


**Default:**::

  "kube-prometheus-stack"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_stack_release_name:

``yk8s.k8s-service-layer.prometheus.prometheus_stack_release_name``
###################################################################



**Type:**::

  Helm chart release name


**Default:**::

  "prometheus-stack"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_stack_version:

``yk8s.k8s-service-layer.prometheus.prometheus_stack_version``
##############################################################

Version of the Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "78.5.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes:

``yk8s.k8s-service-layer.prometheus.remote_writes``
###################################################



**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.basic_auth_secret_name:

``yk8s.k8s-service-layer.prometheus.remote_writes.*.basic_auth_secret_name``
############################################################################

Name of the secret containing htpasswd for basic authentication of Prometheus remote write.
The secret must contain the following keys:
- username: FOO
- password: BAR


**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.url:

``yk8s.k8s-service-layer.prometheus.remote_writes.*.url``
#########################################################



**Type:**::

  RFC3986 HTTP(S) URL


**Example:**::

  "http://remote-write-receiver:9090/api/v1/write"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.write_relabel_configs:

``yk8s.k8s-service-layer.prometheus.remote_writes.*.write_relabel_configs``
###########################################################################

A list of RelabelConfigs, see
https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md#monitoring.coreos.com/v1.RelabelConfig


**Type:**::

  list of (attribute set with items of specific types (action: nonEmptyStr, modulus: unsignedInt, regex: nonEmptyStr, replacement: nonEmptyStr, separator: str, sourceLabels: listOf, targetLabel: prometheusLabelName))


**Example:**::

  [
    {
      replacement = "my-cluster";
      targetLabel = "prometheus";
    }
    {
      replacement = "my-cluster";
      targetLabel = "cluster";
    }
  ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.scheduling_key:

``yk8s.k8s-service-layer.prometheus.scheduling_key``
####################################################

Scheduling keys control where services may run. A scheduling key corresponds
to both a node label and to a taint. In order for a service to run on a node,
it needs to have that label key.
If no scheduling key is defined for service, it will run on any untainted
node.


**Type:**::

  null or Kubernetes label


**Default:**::

  null


**Example:**::

  "${scheduling_key_prefix}/monitoring"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_chart_version:

``yk8s.k8s-service-layer.prometheus.thanos_chart_version``
##########################################################

Version of the Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "17.2.3"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compact_resources:

``yk8s.k8s-service-layer.prometheus.thanos_compact_resources``
##############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compact_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_compact_resources.limits.cpu``
#########################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compact_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.thanos_compact_resources.limits.memory``
############################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "200Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compact_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_compact_resources.requests.cpu``
###########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compact_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.thanos_compact_resources.requests.memory``
##############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.thanos_compact_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compactor_size:

``yk8s.k8s-service-layer.prometheus.thanos_compactor_size``
###########################################################

You can explicitly set the PV size for each component.
If left undefined, the helm chart defaults will be used

Immutable when deployed. (See also :ref:`cluster-configuration.prometheus-configuration.updating-immutable-options`)


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_file:

``yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_file``
######################################################################

Note: The given path is interpreted as being relative to the cluster repo's config directory.


**Type:**::

  null or Relative POSIX path (without special '.' and '..')


**Default:**::

  null


**Example:**::

  "./monitoring/thanos_objectstorage.config"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_objectstorage_container_name:

``yk8s.k8s-service-layer.prometheus.thanos_objectstorage_container_name``
#########################################################################



**Type:**::

  Openstack Swift container name


**Default:**::

  "\${config.yk8s.infra.cluster_name}-monitoring-thanos-data"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_additional_store_endpoints:

``yk8s.k8s-service-layer.prometheus.thanos_query_additional_store_endpoints``
#############################################################################

Provide a list of DNS endpoints for additional thanos store endpoints.
The endpoint will be extended to `dnssrv+_grpc._tcp.{{ endpoint }}.monitoring.svc.cluster.local`.


**Type:**::

  list of RFC1123 subdomain label


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_resources:

``yk8s.k8s-service-layer.prometheus.thanos_query_resources``
############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_query_resources.limits.cpu``
#######################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.thanos_query_resources.limits.memory``
##########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "786Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_query_resources.requests.cpu``
#########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  "1"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.thanos_query_resources.requests.memory``
############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.thanos_query_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources:

``yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources``
##############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.limits.cpu``
#########################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.limits.memory``
############################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "256Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.requests.cpu``
###########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "500m"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.requests.memory``
##############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storage_class:

``yk8s.k8s-service-layer.prometheus.thanos_storage_class``
##########################################################

Thanos uses emptyDirs by default for its components
for faster access.
If that's not feasible, a storage class can be set to
enable persistence and the size for each component volume
can be configured.
Note that switching between persistence requires
manual intervention and it may be necessary to reinstall
the helm chart completely.


**Type:**::

  null or RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_in_memory_max_size:

``yk8s.k8s-service-layer.prometheus.thanos_store_in_memory_max_size``
#####################################################################

https://thanos.io/tip/components/store.md/#in-memory-index-cache
Note: Unit must be specified as decimal! (MB,GB)
This value should be chosen in a sane matter based on
thanos_store_memory_request and thanos_store_memory_limit


**Type:**::

  null or Bytes with units based on powers of 10


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources:

``yk8s.k8s-service-layer.prometheus.thanos_store_resources``
############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.cpu``
#######################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.memory:

``yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.memory``
##########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "2Gi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.requests.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_store_resources.requests.cpu``
#########################################################################

PROMETHEUS POD RESOURCE LIMITS
The following limits are applied to the respective pods.
Note that the Prometheus limits are chosen fairly conservatively and may need
tuning for larger and smaller clusters.
By default, we prefer to set limits in such a way that the Pods end up in the
Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
same value).


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  "500m"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.thanos_store_resources.requests.memory``
############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storegateway_size:

``yk8s.k8s-service-layer.prometheus.thanos_storegateway_size``
##############################################################

You can explicitly set the PV size for each component.
If left undefined, the helm chart defaults will be used

Immutable when deployed. (See also :ref:`cluster-configuration.prometheus-configuration.updating-immutable-options`)


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.use_grafana:

``yk8s.k8s-service-layer.prometheus.use_grafana``
#################################################

Enable grafana

**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.use_thanos:

``yk8s.k8s-service-layer.prometheus.use_thanos``
################################################

Whether to enable use of Thanos.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix

