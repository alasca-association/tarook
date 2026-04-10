Releasenotes
============

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.0.0/>`__,
and this project will adhere to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`__.

We use `towncrier <https://github.com/twisted/towncrier>`__ for the
generation of our release notes file.

Information about unreleased changes can be found
`here <https://gitlab.com/yaook/k8s/-/tree/devel/docs/_releasenotes?ref_type=heads>`__.

General information about release upgrades are documented at
:doc:`/user/guide/upgrade-release`.

.. towncrier release notes start

v12.1.2 (2026-04-10)
--------------------

Bugfixes
~~~~~~~~

- A minor bug in ``tools/vault/init.sh`` has been fixed. (`!2427 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2427>`_)


v12.1.1 (2026-03-23)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.14.4 to 4.14.5
  due to recently published `CVE-2026-4342 <https://www.cve.org/cverecord?id=CVE-2026-4342>`__ (`!2396 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2396>`_)


v12.1.0 (2026-03-12)
--------------------

New Features
~~~~~~~~~~~~

- The helm chart for Calico can now be configured with arbitrary values through :ref:`configuration-options.yk8s.kubernetes.network.calico.helm.values`. (`!1568 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1568>`_)
- The helm chart for FluxCD can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.fluxcd.helm.values`. (`!1808 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1808>`_)
- The helm chart for the Cloud Controller Manager can now be configured with arbitrary values through :ref:`configuration-options.yk8s.openstack.cloud_controller_manager.helm.values`. (`!1811 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1811>`_)
- The helm chart for the Cinder CSI driver plugin can now be configured with arbitrary values through :ref:`configuration-options.yk8s.openstack.cinder.helm.values`. (`!1811 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1811>`_)
- The ability to boot OpenStack instances from volumes has been enhanced with more granular configuration options.
  Formerly limited to enabling or disabling this feature for all instances at once, it can now be configured at multiple levels:

  * Node-level: Configure the usage for individual nodes

    * :ref:`configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume`

  * Group-defaults-level: Configure the usage by default for a group of nodes

    * :ref:`configuration-options.yk8s.openstack.gateway_defaults.create_root_disk_on_volume`
    * :ref:`configuration-options.yk8s.openstack.master_defaults.create_root_disk_on_volume`
    * :ref:`configuration-options.yk8s.openstack.worker_defaults.create_root_disk_on_volume`


  * Global level: Configure the usage for all nodes

    * :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`

  . (`!2225 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2225>`_)
- The :ref:`wg-up.sh<actions-references.wg-upsh>` action script has been extended by the possibility
  to establish a tunnel to the Kubernetes Pod and Service networks in addition. (`!2287 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2287>`_)
- Support for Kubernetes v1.35 has been added. (`!2302 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2302>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- We now use the same version of Calico for all supported Kubernetes versions. This means that Calico will be updated in Clusters that are not on the latest supported Kubernetes version. (`!1568 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1568>`_, `!2324 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2324>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.13.7 to 4.14.3 (`!2195 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2195>`_)
- Updated default version of helm chart rook-ceph of https://github.com/rook/rook from v1.18.6 to v1.18.9 (`!2204 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2204>`_)
- In clusters using GPU worker nodes, the nvidia-device-plugin Pod running on a node is not force restarted after a Kubernetes upgrade anymore.
  This was previously necessary as the nvidia-device-plugin marked a GPU as unhealthy on ``systemctl reload`` with a following restart of kubelet. (`!2216 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2216>`_)
- When booting OpenStack instances from volumes is configured via one of the following options:

  * :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`
  * :ref:`configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume`
  * :ref:`configuration-options.yk8s.openstack.gateway_defaults.create_root_disk_on_volume`
  * :ref:`configuration-options.yk8s.openstack.master_defaults.create_root_disk_on_volume`
  * :ref:`configuration-options.yk8s.openstack.worker_defaults.create_root_disk_on_volume`

  the respective volumes are no longer tried to be allocated in the same availability zone as the instance.
  This is because Cinder availibility zone configurations often differ from Nova availability zones in standard OpenStack setups. (`!2225 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2225>`_)
- The Thanos datasource has been made editable inside of Grafana.
  This does only effect clusters having
  :ref:`configuration-options.yk8s.kubernetes.monitoring.enabled`
  as well as
  :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.use_thanos`
  and
  :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.use_grafana`
  enabled. (`!2253 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2253>`_)
- Grafana alerts for the Thanos datasource have been disabled as this potentially causes doubled alerts.
  This does only effect clusters having
  :ref:`configuration-options.yk8s.kubernetes.monitoring.enabled`
  as well as
  :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.use_thanos`
  and
  :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.use_grafana`
  enabled. (`!2253 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2253>`_)
- Updated default version of helm chart nvidia-device-plugin of https://github.com/NVIDIA/k8s-device-plugin from 0.18.0 to 0.18.2 (`!2265 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2265>`_)
- For clusters running on top of OpenStack, firewall rules have been added which allow traffic flow to the Kubernetes Pod and Service network via the Wireguard tunnel. (`!2287 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2287>`_)
- Vault ServiceMonitor will now only scrape the active(leading) instance. This has been adopted to match the official helm chart behaviour. (`!2290 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2290>`_, `!2337 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2337>`_)
- Updated default version of helm chart etcdbackup from 1.0.0 to 1.2.0 (`!2292 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2292>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.6.1 to 11.8.0 (`!2293 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2293>`_)
- Updated default version of helm chart prometheus-adapter of https://github.com/prometheus-community/helm-charts from 5.2.0 to 5.2.1 (`!2297 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2297>`_)
- Updated default version of helm chart etcdbackup from 1.2.0 to 1.2.1 (`!2303 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2303>`_)
- Affinity and tolerations have been added to the snapshot-controller
  such that it is ensured to be running on a control plane node. (`!2304 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2304>`_)
- An affinity has been added to Calico/Typha such that is scheduled to the control plane by default. (`!2304 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2304>`_)
- Affinity and tolerations have been added to the cinder-csi-controllerplugin
  such that it is ensured to be running on a control plane node. (`!2304 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2304>`_)
- The ``system-cluster-critical`` priority class has been added to the snapshot-controller. (`!2304 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2304>`_)
- Updated default version of helm chart tigera-operator of https://github.com/projectcalico/calico from v3.30.2 to v3.30.6 (`!2306 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2306>`_)
- Updated default version of helm chart prometheus-adapter of https://github.com/prometheus-community/helm-charts from 5.2.1 to 5.3.0 (`!2308 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2308>`_)
- Updated default version of helm chart openstack-cinder-csi of https://github.com/kubernetes/cloud-provider-openstack from 2.34.1 to 2.34.3 (`!2311 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2311>`_)
- Updated default version of helm chart openstack-cloud-controller-manager of https://github.com/kubernetes/cloud-provider-openstack from 2.34.1 to 2.34.2 (`!2312 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2312>`_)
- Updated default version of helm chart openstack-cinder-csi of https://github.com/kubernetes/cloud-provider-openstack from 2.34.3 to 2.35.0 (`!2314 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2314>`_)
- Updated default version of helm chart openstack-cloud-controller-manager of https://github.com/kubernetes/cloud-provider-openstack from 2.34.2 to 2.35.0 (`!2315 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2315>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.19.3 to v1.19.4 (`!2317 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2317>`_)
- The operating system restart behavior has been improved.
  Nodes are only rebooted if a package requires it. (`!2318 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2318>`_)
- Updated default version of helm chart etcdbackup from 1.2.1 to 1.3.0 (`!2320 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2320>`_)
- The volume-snapshot-controller version is not mapped to Kubernetes versions anymore.
  This means that the volume-snapshot-controller will be updated in clusters that are not on the latest supported Kubernetes version.
  The volume-snapshot-controller is internally managed and tested against all supported Kubernetes versions. (`!2324 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2324>`_)
- Updated default version of helm chart etcdbackup from 1.3.0 to 1.4.0 (`!2329 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2329>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.14.3 to 4.14.4 (`!2332 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2332>`_)


Bugfixes
~~~~~~~~

- A bug has been fixed which prevented :ref:`configuration-options.yk8s.openstack.nodes.<name>.root_disk_size` from taking effect. (`!2225 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2225>`_)
- A bug has been fixed that caused nodes to be rebooted multiple times. (`!2286 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2286>`_)
- Affinity and tolerations have been fixed for all components of the prometheus-stack
  such that it can be installed in clusters where all nodes are tainted if a proper
  :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.scheduling_key`
  is configured. (`!2304 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2304>`_)
- Affinity and tolerations have been fixed for the ngninx-ingress-controller admission webhook
  such that it can be installed in clusters where all nodes are tainted if a proper
  :ref:`configuration-options.yk8s.k8s-service-layer.ingress.scheduling_key`
  is configured. (`!2304 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2304>`_)
- Affinity and tolerations have been fixed for Vault backups
  such that it can be installed in clusters where all nodes are tainted if a proper
  :ref:`configuration-options.yk8s.k8s-service-layer.vault.scheduling_key`
  is configured. (`!2304 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2304>`_)
- For clusters using the :doc:`Vault development setup </developer/explanation/vault>`,
  the state directory of the local Vault container is now automatically added to ``.gitignore``.
  If not ignored, the state directory potentially causes issues due to its ownership and restrictive permissions. (`!2310 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2310>`_)
- A bug has been fixed that caused Vault related scripts to silently fail. (`!2323 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2323>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Add ability to autobuild/watch docs for changes and add docs on how to use this feature (`!2203 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2203>`_)
- The :ref:`Vault pivot guide <vault.pivoting>` has been fixed (`!2212 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2212>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- The import script for migrating pre-v1 clusters to Vault have been removed (`!2213 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2213>`_)


Other Tasks
~~~~~~~~~~~

- `!2291 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2291>`_, `!2294 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2294>`_, `!2299 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2299>`_, `!2313 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2313>`_, `!2319 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2319>`_, `!2322 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2322>`_, `!2330 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2330>`_, `!2331 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2331>`_


Misc
~~~~

- `!2269 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2269>`_, `!2305 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2305>`_, `!2309 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2309>`_, `!2321 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2321>`_
