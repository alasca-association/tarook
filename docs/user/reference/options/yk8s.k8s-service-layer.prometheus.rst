.. _configuration-options.yk8s.k8s-service-layer.prometheus:

yk8s.k8s-service-layer.prometheus
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


The used prometheus-based monitoring setup will be explained in more
detail soon :)

.. note::

  To enable prometheus,
  ``k8s-service-layer.prometheus.install`` and
  ``kubernetes.monitoring.enabled`` need to be set to ``true``.


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
the following configuration options:

.. code:: nix

  k8s-service-layer.prometheus.thanos_store_in_memory_max_size = "XGB";
  k8s-service-layer.prometheus.thanos_store_memory_request = "XGi";
  k8s-service-layer.prometheus.thanos_store_memory_limit = "XGi";

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

.. code:: nix

  k8s-service-layer.prometheus.thanos_storage_class = "SOME_STORAGE_CLASS";
  k8s-service-layer.prometheus.thanos_storegateway_size = "XGi";
  k8s-service-layer.prometheus.thanos_compactor_size = "YGi";

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

  positive integer, meaning >0


**Default:**::

  1


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_resources:

``yk8s.k8s-service-layer.prometheus.alertmanager_resources``
############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.alertmanager_resources.limits.cpu``
#######################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "256Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.alertmanager_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.alertmanager_resources.requests.memory``
############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.alertmanager_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.blackbox_version:

``yk8s.k8s-service-layer.prometheus.blackbox_version``
######################################################

Deploy a specific blackbox exporter version
https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter


**Type:**::

  non-empty string


**Default:**::

  "9.8.0"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.common_labels:

``yk8s.k8s-service-layer.prometheus.common_labels``
###################################################

If at least one common_label is defined, Prometheus will be created with selectors
matching these labels and only ServiceMonitors that meet the criteria of the selector,
i.e. are labeled accordingly, are included by Prometheus.
The LCM takes care that all ServiceMonitors created by itself are labeled accordingly.
The key can not be "release" as that one is already used by the Prometheus helm chart.


**Type:**::

  attribute set of non-empty string


**Default:**::

  { }


**Example:**::

  {
    managed-by = "yaook-k8s";
  }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_admin_secret_name:

``yk8s.k8s-service-layer.prometheus.grafana_admin_secret_name``
###############################################################



**Type:**::

  non-empty string


**Default:**::

  "cah-grafana-admin"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_dashboard_enable_multicluster_support:

``yk8s.k8s-service-layer.prometheus.grafana_dashboard_enable_multicluster_support``
###################################################################################

Enable referencing multiple K8s clusters by a single Grafana datasource.


**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_persistent_storage_class:

``yk8s.k8s-service-layer.prometheus.grafana_persistent_storage_class``
######################################################################

If this variable is defined, Grafana will store its data in a PersistentVolume
in the defined StorageClass. Otherwise, persistence is disabled for Grafana.
The value has to be a valid StorageClass available in your cluster.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_resources:

``yk8s.k8s-service-layer.prometheus.grafana_resources``
#######################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.grafana_resources.limits.cpu``
##################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "512Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "100m"


**Example:**::

  "500m"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.grafana_resources.requests.memory``
#######################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.grafana_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.grafana_root_url:

``yk8s.k8s-service-layer.prometheus.grafana_root_url``
######################################################

The full public facing url you use in browser, used for redirects and emails


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.install:

``yk8s.k8s-service-layer.prometheus.install``
#############################################

If kubernetes.monitoring.enabled is true, choose whether to install or uninstall
Prometheus. IF SET TO FALSE, PROMETHEUS WILL BE DELETED WITHOUT CHECKING FOR
DISRUPTION (sic!).


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets``
############################################################



**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.interval:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.interval``
#######################################################################

Scraping interval. Overrides value set in `defaults`


**Type:**::

  non-empty string


**Default:**::

  "60s"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module``
#####################################################################

module to be used.

"http_api" allows status codes 200, 300 and 401


**Type:**::

  one of "http_2xx", "http_api", "http_api_insecure", "icmp", "tcp_connect"


**Default:**::

  "http_2xx"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.name:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.name``
###################################################################

Human readable URL that will appear in Prometheus / AlertManager


**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.scrapeTimeout:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.scrapeTimeout``
############################################################################

Scrape timeout. Overrides value set in `defaults`


**Type:**::

  non-empty string


**Default:**::

  "60s"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.url:

``yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.url``
##################################################################

The URL that blackbox will scrape


**Type:**::

  non-empty string


**Example:**::

  "http://example.com/healthz"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources:

``yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources``
##################################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.limits.cpu``
#############################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "128Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "50m"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.requests.memory``
##################################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.kube_state_metrics_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.manage_thanos_bucket:

``yk8s.k8s-service-layer.prometheus.manage_thanos_bucket``
##########################################################

Let terraform create an object storage container / bucket for you if `true`.
If set to `false` one must provide a valid configuration via Vault
See: https://yaook.gitlab.io/k8s/release/v3.0/managed-services/prometheus/prometheus-stack.html#custom-bucket-management


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.namespace:

``yk8s.k8s-service-layer.prometheus.namespace``
###############################################

Namespace to deploy the monitoring in (will be created if it does not exist, but
never deleted).


**Type:**::

  non-empty string


**Default:**::

  "monitoring"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.node_exporter_textfile_collector_path:

``yk8s.k8s-service-layer.prometheus.node_exporter_textfile_collector_path``
###########################################################################



**Type:**::

  non-empty string


**Default:**::

  "/var/lib/node_exporter/textfile_collector"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_repo_url:

``yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_repo_url``
########################################################################



**Type:**::

  non-empty string


**Default:**::

  "https://nvidia.github.io/dcgm-exporter/helm-charts"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_version:

``yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_version``
#######################################################################

Helm chart version of the NVIDIA DCGM exporter


**Type:**::

  non-empty string


**Default:**::

  "4.1.1"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources:

``yk8s.k8s-service-layer.prometheus.operator_resources``
########################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.operator_resources.limits.cpu``
###################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "400Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.operator_resources.requests.memory``
########################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.operator_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_adapter_release_name:

``yk8s.k8s-service-layer.prometheus.prometheus_adapter_release_name``
#####################################################################



**Type:**::

  non-empty string


**Default:**::

  "prometheus-adapter"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_adapter_version:

``yk8s.k8s-service-layer.prometheus.prometheus_adapter_version``
################################################################



**Type:**::

  non-empty string


**Default:**::

  "4.14.1"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_helm_repo_url:

``yk8s.k8s-service-layer.prometheus.prometheus_helm_repo_url``
##############################################################



**Type:**::

  non-empty string


**Default:**::

  "https://prometheus-community.github.io/helm-charts"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_persistent_storage_class:

``yk8s.k8s-service-layer.prometheus.prometheus_persistent_storage_class``
#########################################################################

Configure persistent storage for Prometheus
By default an empty-dir is used.
https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_persistent_storage_resource_request:

``yk8s.k8s-service-layer.prometheus.prometheus_persistent_storage_resource_request``
####################################################################################

Configure persistent storage for Prometheus
https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md


**Type:**::

  string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "50Gi"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources:

``yk8s.k8s-service-layer.prometheus.prometheus_resources``
##########################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.prometheus_resources.limits.cpu``
#####################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "3Gi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "1"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.prometheus_resources.requests.memory``
##########################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.prometheus_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_service_name:

``yk8s.k8s-service-layer.prometheus.prometheus_service_name``
#############################################################



**Type:**::

  non-empty string


**Default:**::

  "prometheus-operated"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_stack_chart_name:

``yk8s.k8s-service-layer.prometheus.prometheus_stack_chart_name``
#################################################################



**Type:**::

  non-empty string


**Default:**::

  "prometheus-community/kube-prometheus-stack"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_stack_release_name:

``yk8s.k8s-service-layer.prometheus.prometheus_stack_release_name``
###################################################################



**Type:**::

  non-empty string


**Default:**::

  "prometheus-stack"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_stack_version:

``yk8s.k8s-service-layer.prometheus.prometheus_stack_version``
##############################################################

helm chart version of the prometheus stack
https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
If you set this empty (not unset), the latest version is used
Note that upgrades require additional steps and maybe even LCM changes are needed:
https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#upgrading-chart


**Type:**::

  non-empty string


**Default:**::

  "73.2.0"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes:

``yk8s.k8s-service-layer.prometheus.remote_writes``
###################################################



**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.basic_auth_secret_name:

``yk8s.k8s-service-layer.prometheus.remote_writes.*.basic_auth_secret_name``
############################################################################

Name of the secret containing htpasswd for basic authentication of Prometheus remote write.
The secret must contain the following keys:
- username: FOO
- password: BAR


**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.url:

``yk8s.k8s-service-layer.prometheus.remote_writes.*.url``
#########################################################



**Type:**::

  string


**Example:**::

  "http://remote-write-receiver:9090/api/v1/write"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.write_relabel_configs:

``yk8s.k8s-service-layer.prometheus.remote_writes.*.write_relabel_configs``
###########################################################################

A list of RelabelConfigs, see
https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.RelabelConfig


**Type:**::

  list of (attribute set)


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.scheduling_key:

``yk8s.k8s-service-layer.prometheus.scheduling_key``
####################################################

Scheduling keys control where services may run. A scheduling key corresponds
to both a node label and to a taint. In order for a service to run on a node,
it needs to have that label key.
If no scheduling key is defined for service, it will run on any untainted
node.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Example:**::

  "\${config.yk8s.node-scheduling.scheduling_key_prefix}/monitoring"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_chart_version:

``yk8s.k8s-service-layer.prometheus.thanos_chart_version``
##########################################################

Set custom Bitnami/Thanos chart version


**Type:**::

  non-empty string


**Default:**::

  "16.0.7"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compact_resources:

``yk8s.k8s-service-layer.prometheus.thanos_compact_resources``
##############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compact_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_compact_resources.limits.cpu``
#########################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "200Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compact_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.thanos_compact_resources.requests.memory``
##############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.thanos_compact_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compactor_size:

``yk8s.k8s-service-layer.prometheus.thanos_compactor_size``
###########################################################

You can explicitly set the PV size for each component.
If left undefined, the helm chart defaults will be used

Immutable when deployed. (See also :ref:`cluster-configuration.prometheus-configuration.updating-immutable-options`)


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_file:

``yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_file``
######################################################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_path:

``yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_path``
######################################################################



**Type:**::

  non-empty string


**Default:**::

  "{{ playbook_dir }}/../../../config"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_objectstorage_container_name:

``yk8s.k8s-service-layer.prometheus.thanos_objectstorage_container_name``
#########################################################################



**Type:**::

  non-empty string


**Default:**::

  "\${config.yk8s.infra.cluster_name}-monitoring-thanos-data"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_additional_store_endpoints:

``yk8s.k8s-service-layer.prometheus.thanos_query_additional_store_endpoints``
#############################################################################

Provide a list of DNS endpoints for additional thanos store endpoints.
The endpoint will be extended to `dnssrv+_grpc._tcp.{{ endpoint }}.monitoring.svc.cluster.local`.


**Type:**::

  list of non-empty string


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_resources:

``yk8s.k8s-service-layer.prometheus.thanos_query_resources``
############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_query_resources.limits.cpu``
#######################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "786Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "100m"


**Example:**::

  "1"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_query_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.thanos_query_resources.requests.memory``
############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.thanos_query_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources:

``yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources``
##############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.limits.cpu``
#########################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "256Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "500m"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.requests.memory``
##############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.thanos_sidecar_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_in_memory_max_size:

``yk8s.k8s-service-layer.prometheus.thanos_store_in_memory_max_size``
#####################################################################

https://thanos.io/tip/components/store.md/#in-memory-index-cache
Note: Unit must be specified as decimal! (MB,GB)
This value should be chosen in a sane matter based on
thanos_store_memory_request and thanos_store_memory_limit


**Type:**::

  null or string matching the pattern [0-9]+.[0-9]+([kMGTPEZYRQ]B)|[1-9][0-9]*([kMGTPEZYRQ]B)?


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources:

``yk8s.k8s-service-layer.prometheus.thanos_store_resources``
############################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.cpu:

``yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.cpu``
#######################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "2Gi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "100m"


**Example:**::

  "500m"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.requests.memory:

``yk8s.k8s-service-layer.prometheus.thanos_store_resources.requests.memory``
############################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storegateway_size:

``yk8s.k8s-service-layer.prometheus.thanos_storegateway_size``
##############################################################

You can explicitly set the PV size for each component.
If left undefined, the helm chart defaults will be used

Immutable when deployed. (See also :ref:`cluster-configuration.prometheus-configuration.updating-immutable-options`)


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


.. _configuration-options.yk8s.k8s-service-layer.prometheus.use_grafana:

``yk8s.k8s-service-layer.prometheus.use_grafana``
#################################################

Enable grafana

**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/monitoring.nix

