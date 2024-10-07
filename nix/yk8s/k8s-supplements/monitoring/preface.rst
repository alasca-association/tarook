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
