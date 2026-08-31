Tarook uses the Prometheus community's `kube-prometheus-stack <https://github.com/prometheus-community/helm-charts>`__
Helm chart to deploy Kubernetes cluster monitoring.

.. note::

   To enable Prometheus,
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

- :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storegateway_in_memory_max_size`
- :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storegateway_resources.limits.memory`
- :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storegateway_resources.requests.memory`

Note that the value must be a decimal unit!
Please also note that
if no explicit memory limit is configured
the Helm chart default is used which is not optimal.
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
