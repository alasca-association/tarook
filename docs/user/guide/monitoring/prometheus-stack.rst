Prometheus Stack
================

yaook/k8s uses the kube-prometheus-stack helm chart with an additional
abstraction layer.
To figure out the used version, you could use:

.. code:: console

    $ helm ls -n monitoring

Take a look at the ``values.yaml`` files of
the individual helm charts to see what you can (or can`t) potentially
modify.
Note that not all values might be exposed in the
``config.toml``. The data path is
``config.toml -> inventory/prometheus.yaml -> monitoring_v2 -> templates/prometheus_stack.yaml.j2``.
If a field that you need isn’t listed in ``prometheus_stack.yaml`` or
statically configured, please
`open an issue <https://gitlab.com/yaook/k8s/-/issues>`__
or, even preferable,
`submit a merge request :) <https://gitlab.com/yaook/k8s/-/merge_requests>`__.
yaook/k8s’ developer guide can be found
`here <https://yaook.gitlab.io/meta/01-developing.html#workflow>`__.

Yaook/k8s also allows the upgrade of the kube-prometheus-stack.
You can adjust the ``prometheus_stack_version`` in the ``config.toml``

.. code:: toml

   ...
   [monitoring]
   ...
   prometheus_stack_version = 48.8.8
   ...

If the variable isn`t set, the default will be used, which can be found via the
following call as ``monitoring_prometheus_stack_version``.

.. code:: console

    $ cat managed-k8s/k8s-service-layer/roles/monitoring_v2/defaults/main.yaml

This file also lists currently supported versions.
As each upgrade requires further steps, i.e. updating the CRDs,
you cannot simply jump ahead.

The upgrade routine can be triggered by running the following:

.. code:: console

    $ MANAGED_K8S_RELEASE_THE_KRAKEN=true AFLAGS="--diff -t monitoring" bash managed-k8s/actions/apply-k8s-supplements.sh

Grafana
-------

The LCM uses the
`Grafana helm chart <https://github.com/grafana/helm-charts/tree/main/charts/grafana>`__
with the version that comes with the current kube-prometheus-stack helm
chart version.
Grafana is not enabled by default,
you can enable it in the
:ref:`Prometheus configuration<cluster-configuration.prometheus-configuration>`.


Custom dashboards and datasources
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default, Grafana will be rolled with two sidecars
(``grafana-sc-dashboard``, ``grafana-sc-datasources``) that are
configured to pick up *additional* dashboards/datasources in *any*
namespace. These extra resources can reside either in k8s ``Secrets`` or
in ``ConfigMaps``. They have to have a label ``grafana_dashboard`` set.
To configure a custom, *logical* folder for one or more dashboard, add
the annotation ``customer-dashboards=<Folder name>``.

.. note::
   After 30s seconds of research the author came to the conclusion that one
   cannot nest logical dashboard folders in Grafana. If ``<Folder name>``
   consists of a path of multiple folders, only the last one is picked.

As an example, let’s add a dashboard for the NGINX Ingress Controller
and have it displayed under the logical ``nginx`` folder in Grafana. The
backing configmap for the dashboard should be stored in the namespace
``fancy``.

1. Download the dashboard as
   `JSON <https://grafana.com/grafana/dashboards/9614?pg=dashboards&plcmt=featured-dashboard-4>`__
   to your workstation. We will call that manifest ``nginx_db.json``.
2. Create the configmap:
   ``kubectl create configmap nginx-db -n fancy --from-file=nginx_db.json``
3. Add a label so that the sidecar will pick up the dashboard:
   ``kubectl label cm -n fancy nginx-db grafana_dashboard=1``. (The
   value of the key/value label pair does not matter)
4. Annotate the configmap with the proper path:
   ``kubectl annotate cm -n fancy nginx-db customer-dashboards=nginx``.

The sidecar should pick up the change eventually. If it doesn’t or
you’re impatient, you could restart Grafana by destroying its pod.

Alertmanager
------------

The monitoring stack comes with an alertmanager instance that is
available to the end user for their convenience. One can create also
their own ``Alertmanager`` resource which is then translated into a
``StatefulSet`` by the prometheus operator. AM configuration should be
kept separate and can be injected by creating a ``AlertmanagerConfig``
resource within the ``monitoring`` namespace. Other namespace are not
considered without further configuration. For further information please
refer to the
`corresponding documentation. <https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/alerting.md>`__
A silly example:

.. code:: yaml

   kind: AlertmanagerConfig
   apiVersion: monitoring.coreos.com/v1alpha1
   metadata:
     name: custom-amc
     namespace: monitoring
   spec:
     receivers:
       - name: your mom
         emailConfigs:
           - hello: localhost
             requireTLS: true
             to: a@b.de
             smarthost: a.com:25
             from: c@d.de
         pagerdutyConfigs:
           - url: https://events.pagerduty.com/v2/enqueue
             routingKey:
               key: a
               name: blub
               optional: true
     route:
       receiver: your mom
       groupBy:
       - job
       continue: false
       routes:
       - receiver: your mom
         match:
           alertname: Watchdog
         continue: false
       groupWait: 30s
       groupInterval: 5m
       repeatInterval: 12h

.. note::

   The author hasn’t worked much with ``Alertmanager(Config)`` in
   the past and only ensured that manifests are read correctly. Their test
   was looking at

   .. code:: console

      $ k exec -ti -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0 -- amtool --alertmanager.url=http://127.0.0.1:9093 config

.. note::

   You will probably mess up the ``AlertmanagerConfig`` manifest in
   one way or another. The AdmissionController caught some typos. On other
   occasions I had to look into the logs of the ``prometheus-operator``
   pod. And eventually the AM failed to come up because I missed some
   further fields which I figured via the logs of the ``AM`` pod.

.. _prometheus-stack.thanos:

Thanos
------

`Thanos <https://thanos.io/>`__ is deployed outside of the kube-prometheus-stack helm chart.
By default, it writes its metrics into a SWIFT object storage container
that resides in the same OpenStack project.

We're deploying the `Bitnami Thanos helm chart <https://github.com/bitnami/charts/tree/main/bitnami/thanos>`__
with adjusted values by default.
Please refer to its documentation for further details.

Thanos can be enabled and configured in the
:ref:`Prometheus configuration<cluster-configuration.prometheus-configuration>`.

In previous times, Thanos has been deployed via JSONNET.
You must migrate to the helm chart as soon as possible as the
JSONNET-based installation method is deprecated and will be dropped very soon.
The migration is automatically triggered on a subsequent rollout of ``monitoring_v2``.
If you want to postpone this, you must set the following in your ``config/config.toml``:

.. code:: toml

   ...
   [k8s-service-layer.prometheus]
   ...
   use_helm_thanos = false
   ...

Object Storage Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can either choose the automated
Thanos object storage management (default) in which case
the LCM takes care to create a bucket inside
your OpenStack project or you can configure
a custom bucket.

Automated bucket management
"""""""""""""""""""""""""""

.. warning::

   The automated bucket management can only be used when your cluster
   is created on top of OpenStack and a valid OpenStack RC file is sourced.

This method is enabled by default.
This will let Terraform create an object storage container
inside your OpenStack project and automatically configures
Thanos to use that container as primary storage.


Custom bucket management
""""""""""""""""""""""""

The custom bucket management can be enabled by setting
``k8s-service-layer.prometheus.manage_thanos_bucket``
to ``false``
in your ``config/config.toml``.

You must supply a valid configuration for a
`supported Thanos client <https://thanos.io/tip/thanos/storage.md/#supported-clients>`__.

This configuration must be stored in your cluster key-value secrets engine
under ``kv/data/thanos-config``.
Inserting a Thanos client config into vault can be automated by storing the
configuration at ``config/thanos.yaml`` (or specifying another location
in your ``config/config.toml`` under
``k8s-service-layer.prometheus.thanos_objectstorage_config_file``)
and then triggering the vault update script:

.. code:: shell

   ./managed-k8s/tools/vault/update.sh

Alternatively, you can also manually insert your configuration into vault.


Prometheus Adapter (metrics server)
-----------------------------------

Background and motivation
~~~~~~~~~~~~~~~~~~~~~~~~~

The
`prometheus-adapter <https://github.com/kubernetes-sigs/prometheus-adapter>`__
provides the
`metrics API <https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/>`__
by making use of existing prometheus metrics. In case of default
resources (memory and cpu per pod/node), prometheus fetches these
metrics from kubelet which, on the hand, reads these values from
cAdvisor which gets its values from cgroups on the individual node.
`metrics-server <https://github.com/kubernetes-sigs/metrics-server>`__
gets those metrics directly from kubelet/cAdvisor.

A common use case for the metrics API is horizontal (HPA) and vertical
pod autoscaling (VPA). An advantage of prometheus-adapter compared to
metrics-server is that one can define custom metrics for HPA and VPA.
``kubectl top nodes`` and ``kubectl top pods`` also needs a working
metrics API :)

As stated above, the values of the metrics API are derived stats of the
cgroups on the node. kubelet creates a resource tree with the layers

-  QoS (Guaranteed, Burstable, BestEffort)
-  Pod
-  Container

A sample tree:

::

   root@managed-k8s-worker-1:/sys/fs/cgroup/unified/kubepods.slice# tree -d
   .
   ├── kubepods-besteffort.slice
   │   ├── kubepods-besteffort-pod1793a176_009e_4b22_9d89_6d71f914f6f7.slice
   │   │   ├── docker-2dbb7f0327a157479fda466398aa87664069610232b293f5817b2712b9ff5719.scope
   │   │   └── docker-51fdb8e253c7873a04db7219fb602694ad3977957a8ee354d362ce25cd29d3c8.scope
   │   ├── kubepods-besteffort-pod2c9a23a5_effa_4130_aa19_5efac4829224.slice
   │   │   ├── docker-817cb87c8d31136e3ef7d6274393127184b4781367bf3b9b62e572b796ebecd4.scope
   │   │   └── docker-bb2c7f5087e52182667e63fc548fbb15d7981fa7322b58b59c529bbca71a8361.scope
   │   ├── kubepods-besteffort-pod6aaaaf32_9f4e_46fe_841f_13bee2413625.slice
   │   │   ├── docker-3a58ec66ee269a25dc14d580fd9ea4766ff6fcb269b7be39bdc08abd9c0a87f4.scope
   │   │   └── docker-3ad62f52496d25dd5ef3f8b9b462776bbd7023ed1c37c56b19429b8c7b926ad6.scope
   │   ├── kubepods-besteffort-podb2481109_b708_49f3_b2bb_52b0fb470fe9.slice
   │   │   ├── docker-601173595b1d0d6b08b7965e28e04c83a64900e2642d3c48ff0f972019f9f556.scope
   │   │   ├── docker-9edfeb7ab8ae757ffb90e847ffa70b2281e89367eca3f34d89065225e61e47ba.scope
   │   │   └── docker-de4b153c2c49bb04c0b45f534694fd143d70f25b18503626d67a4fd73c016ea5.scope
   │   ├── kubepods-besteffort-podb393dd5c_0c80_488b_bed1_c548aea803a3.slice
   │   │   ├── docker-7f22a8b72620cd7b6d740de9957f10eed127063b64745df8b45b432d299d04f0.scope
   │   │   └── docker-e3a42aca173771b1089d97ba8664d6fd04e9f5ed736a1167c75b3f71025315e9.scope
   │   ├── kubepods-besteffort-podcd213409_756c_4d17_9b7b_9a9b023d8533.slice
   │   │   ├── docker-ab7a790f1afbd39ffaef0ce1bdb0dbbe7b9525ad785190e498b9a68754f96c86.scope
   │   │   └── docker-eac640f0373dc37d45e6d36375656db04d2b815e605d9c8b1c8a2652e1a66e65.scope
   │   └── kubepods-besteffort-podeba9d649_010c_4122_bcee_27255d8ad69c.slice
   │       ├── docker-087baf1b34e7a703d81cbe8a988d2eb9e0837f86b798066789436443cfea090e.scope
   │       └── docker-68c2d4b2f374611a1e550b7f3b31dba3039d5c98b5d931fb87638cf0114bd9a8.scope
   └── kubepods-burstable.slice
       ├── kubepods-burstable-pod4bbb178b_3396_49b7_90e7_6264b7392aa2.slice
       │   ├── docker-5f4521bde3825fa1b35262ed377c95ce47cdd322e2f017a9a8f1083e05a8d39b.scope
       │   ├── docker-6b6d47a682fc95ca0d7c37cf83f391c3d0f8bacda88eae22634b4c5dff043dbf.scope
       │   └── docker-cd817ca433d294ae3701c61dab312ab5715525cf3cd8c74fc5f1471bbcde59c3.scope
       ├── kubepods-burstable-pod793e426b_16c6_4b86_a0b8_e4b4ed877c15.slice
       │   ├── docker-7158fab7cdc1af3bc68599e8fa0cfcc637840a8a9fea65a94cc467e7836310ea.scope
       │   └── docker-92a0b9788b01f2ca82792d93bbdfb90da419097c61493dcd6587fafacace1d91.scope
       └── kubepods-burstable-pod81795b29_e574_4d5e_866c_ad146e86bdbb.slice
           ├── docker-51c9c0b1dcf6153572661b8bcb9d99ea4a4934db35e074fb88297b4b36002ace.scope
           └── docker-dee4dea98d5e8e6282fe64607d3c91e3ee071d2fab2570d44eedac649702daf2.scope

   34 directories

Note: ``/sys/fs/cgroup/unified/`` is the mount point of cgroups v2 on a
Ubuntu 20.04 node. As it seems, cgroups v1 is still the default so,
i.e., information on memory usage have to be fetched from the
corresponding memory controllers.

Those values are translated into such metrics:

::

   container_memory_working_set_bytes{container="POD", endpoint="https-metrics", id="/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-pod00376bc9_6679_4f56_a9dd_a10aad6ff2d4.slice/docker-5b9efdb04ff83031b437fde548968ef9b92c3febccb03946ec421b11d12893dd.scope", image="k8s.gcr.io/pause:3.2", instance="172.30.181.39:10250", job="kubelet", metrics_path="/metrics/cadvisor", name="k8s_POD_prometheus-stack-prometheus-node-exporter-z8qj7_monitoring_00376bc9-6679-4f56-a9dd-a10aad6ff2d4_0", namespace="monitoring", node="managed-k8s-worker-0", pod="prometheus-stack-prometheus-node-exporter-z8qj7", service="prometheus-stack-kube-prom-kubelet"}
       536576
   container_memory_working_set_bytes{container="POD", endpoint="https-metrics", id="/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-pod01ed3a39_a5f0_4465_a33f_63645893aa1e.slice/docker-469c599d81d233dd2a1d6e1ea252ca1535df26e4c57f04451c066bf1589cc129.scope", image="k8s.gcr.io/pause:3.2", instance="172.30.181.39:10250", job="kubelet", metrics_path="/metrics/cadvisor", name="k8s_POD_nvidia-device-plugin-daemonset-4gbd2_kube-system_01ed3a39-a5f0-4465-a33f-63645893aa1e_0", namespace="kube-system", node="managed-k8s-worker-0", pod="nvidia-device-plugin-daemonset-4gbd2", service="prometheus-stack-kube-prom-kubelet"}
       737280
   container_memory_working_set_bytes{container="POD", endpoint="https-metrics", id="/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-pod12321fde_373b_4347_ad3e_f31b4f587d35.slice/docker-2bd3158e1dc1d1911dcb294e62463c6da24517287c77eb132cf22bafe1710bc4.scope", image="k8s.gcr.io/pause:3.2", instance="172.30.181.180:10250", job="kubelet", metrics_path="/metrics/cadvisor", name="k8s_POD_thanos-sample-storegateway-0_monitoring_12321fde-373b-4347-ad3e-f31b4f587d35_0", namespace="monitoring", node="managed-k8s-worker-2", pod="thanos-sample-storegateway-0", service="prometheus-stack-kube-prom-kubelet"}
