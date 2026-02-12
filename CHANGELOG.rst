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

v12.0.0 (2026-02-12)
--------------------

Breaking changes
~~~~~~~~~~~~~~~~

- The deprecated option ``infra.hosts_file`` has been removed. Use :ref:`configuration-options.yk8s.infra.ansible_hosts` instead. (`!1840 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1840>`_)
- :ref:`update-inventory.sh <actions-references.update-inventorysh>` now differentiates between multiple targets. If you directly use ``update-inventory.sh`` in your automation, you must adapt your scripts.
  Run

  .. code:: console

     $ ./managed-k8s/actions/update-inventory.sh help

  for details. (`!1840 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1840>`_)
- Vault policies must be updated for existing Vault instances which serve as backend for clusters.
  A Vault root token is required to do so.

  .. code::

     VAULT_TOKEN=$vault_root_token ./managed-k8s/actions/migrate-to-release.sh

  . (`!2123 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2123>`_)
- Updated default version of helm chart etcdbackup from 0.20251127.0 to 1.0.0 (`!2255 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2255>`_)


New Features
~~~~~~~~~~~~

- The helm chart for cert-manager can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.cert-manager.helm.values`. (`!1807 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1807>`_)
- It is now possible to add custom hooks for pre-drain and post-uncordon roles via :ref:`configuration-options.yk8s.hooks`. (`!1927 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1927>`_)
- The shared secret for :doc:`/user/explanation/services/ch-k8s-lbaas` is now auto-generated and handled via Vault.
  Previously, the user was expected to manually generate and configure it in :ref:`configuration-options.yk8s.ch-k8s-lbaas.shared_secret`. (`!2123 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2123>`_)
- It is now checked that a Kubernetes control-plane node fulfills kubeadm's minimal CPU and memory requirements during node bootstrapping: at least 2 CPUs and 1700MB memory per node. (`!2134 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2134>`_)
- Support for Kubernetes v1.34 has been added. (`!2201 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2201>`_)
- The preparation of Kubernetes nodes can now be separately triggered via

  .. code:: console

     $ bash managed-k8s/actions/apply-k8s-core.sh prepare-k8s-nodes.yaml

  . (`!2245 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2245>`_)
- An option to manage the containerd version on Kubernetes nodes has been introduced: :ref:`configuration-options.yk8s.containerd.version`.

  Previously, the latest available version has been installed which caused issues. (`!2245 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2245>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Updated default version of helm chart rook-ceph of https://github.com/rook/rook from v1.17.8 to v1.18.5 (`!2077 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2077>`_)
- It is now ensured that all components of ch-k8s-lbaas are deconfigured and absent if the option :ref:`configuration-options.yk8s.ch-k8s-lbaas.enabled` is ``false``. (`!2123 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2123>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.18.3 to v1.19.1 (`!2150 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2150>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 78.2.1 to 78.3.0 (`!2167 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2167>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 78.3.0 to 78.3.2 (`!2171 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2171>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.5.2 to 4.6.0 (`!2172 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2172>`_)
- Updated default version of helm chart nvidia-device-plugin of https://github.com/NVIDIA/k8s-device-plugin from 0.17.4 to 0.18.0 (`!2176 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2176>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 78.3.2 to 78.4.0 (`!2177 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2177>`_)
- Updated default version of helm chart etcdbackup from 0.20250918.0 to 0.20251023.0 (`!2181 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2181>`_)
- Updated default version of helm chart prometheus-adapter of https://github.com/prometheus-community/helm-charts from 5.1.0 to 5.2.0 (`!2182 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2182>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 78.4.0 to 78.5.0 (`!2184 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2184>`_)
- Updated default version of helm chart rook-ceph of https://github.com/rook/rook from v1.18.5 to v1.18.6 (`!2189 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2189>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.13.3 to 4.13.6 (`!2194 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2194>`_)
- Updated default version of helm chart etcdbackup from 0.20251023.0 to 0.20251127.0 (`!2218 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2218>`_)
- Tasks have been added which set ``net.netfilter.nf_conntrack_buckets`` to ``65536`` and ``net.netfilter.nf_conntrack_max`` to ``262144`` on frontend nodes (see #837). (`!2221 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2221>`_, `!2267 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2267>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.4.1 to 11.6.0 (`!2222 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2222>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.19.1 to v1.19.2 (`!2226 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2226>`_)
- The script to verify Kubernetes supplements has been renamed to :ref:`verify-10-supplements-health.sh<actions-references.verify-10-supplements-healthsh>`.

  An additional script to verify the healthiness of the Kubernetes API has been introduced: :ref:`verify-00-kubernetes-api.sh<actions-references.verify-00-kubernetes-apish>`.

  It is now checked that the Kubernetes API is healthy after configuring the control plane nodes. (`!2251 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2251>`_)
- The restart of containers of control plane components after e.g. certificate renewal has been improved. (`!2251 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2251>`_)
- The autogeneration header has been removed from Wireguard client templates. (`!2259 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2259>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.6.0 to 11.6.1 (`!2264 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2264>`_)
- Updated default version of helm chart flux2 of https://github.com/fluxcd-community/helm-charts from 2.15.0 to 2.16.4

  .. note::

     Please note that upgrading the flux2 chart to ``>=v2.17.0`` requires patching the CRDs in advance, which is not automated, yet.

  . (`!2276 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2276>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.19.2 to v1.19.3 (`!2278 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2278>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.13.6 to 4.13.7 (`!2280 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2280>`_)
- In the vault-backup deployment, the version of ``yaook/backup-shifter`` has been bumped to ``1.0.329`` and the version of ``yaook/backup-creator`` has been pinned to ``2.0.179``.
  This makes it possible to scrape backup metrics via IPv6. (`!2282 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2282>`_)


Bugfixes
~~~~~~~~

- `Bug #846 <https://gitlab.com/alasca.cloud/tarook/tarook/-/issues/846>`_ was fixed which caused values to be mangled when the same option was set in multiple places. (`!2243 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2243>`_)
- The Kubernetes initialization state is now taken into account when updating frontend nodes. (`!2245 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2245>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- The suggestion to install the `helm diff <https://github.com/databus23/helm-diff>`__ plugin has been added. (`!2162 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2162>`_)
- `!2170 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2170>`_, `!2219 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2219>`_
- Adjusted the description of :ref:`configuration-options.yk8s.k8s-service-layer.rook.nmgrs`. (`!2231 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2231>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- The option :ref:`configuration-options.yk8s.ch-k8s-lbaas.shared_secret` has been marked as deprecated.
  The secret is handled via Vault from now on and if the option is set, the option's value is automatically moved to Vault on a rollout.
  Once a rollout has been done, the option should be unset as it is going to be removed in a future release. (`!2123 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2123>`_)
- Support for Kubernetes v1.31 has been dropped. (`!2251 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2251>`_)


Other Tasks
~~~~~~~~~~~

- `!2169 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2169>`_, `!2173 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2173>`_, `!2185 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2185>`_, `!2186 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2186>`_, `!2197 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2197>`_, `!2198 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2198>`_, `!2200 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2200>`_, `!2202 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2202>`_, `!2205 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2205>`_, `!2227 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2227>`_, `!2229 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2229>`_, `!2256 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2256>`_, `!2268 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2268>`_, `!2276 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2276>`_, `!2279 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2279>`_, `!2284 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2284>`_, `!2295 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2295>`_


Misc
~~~~

- `!1031 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1031>`_, `!2090 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2090>`_, `!2161 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2161>`_, `!2233 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2233>`_, `!2261 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2261>`_
