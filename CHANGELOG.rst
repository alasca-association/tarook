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

v14.0.1 (2026-07-16)
--------------------

Bugfixes
~~~~~~~~

- An incompatibility within action :ref:`destroy.sh<actions-references.destroysh>` has been fixed which caused it to fail in OpenStack environments where a lookup on an OpenStack project by name is forbidden. (`!2558 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2558>`_)


Misc
~~~~

- `!2558 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2558>`_


v14.0.0 (2026-07-02)
--------------------

Breaking Changes
~~~~~~~~~~~~~~~~

- Terraform is now configured using Terranix. The necessary state migration is automatically handled by the migration script.

  .. attention::

     Don't :ref:`switch the backend <configuration-options.yk8s.terraform>` before migrating

  .. attention::

     Ensure that :ref:`apply-terraform.sh <actions-references.apply-terraformsh>` completes successfully before attempting a release migration

  _ (`!1559 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1559>`_, `!2545 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2545>`_, `!2546 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2546>`_)
- The behaviour of :ref:`init-cluster-repo.sh <actions-references.init-cluster-reposh>` has changed:

  * The environment variables ``MANAGED_K8S_LATEST_RELEASE`` and ``MANAGED_K8S_GIT_BRANCH`` are not supported anymore
  * Use ``-b`` to pass a custom branch name instead of passing it as the first argument
  * The first positional argument now allows to select from one of the available templates (currently ``minimal``, ``openstack``, ``proxmox``)

  See :ref:`Initialization (OpenStack) <quick-start.openstack.create-and-initialize-cluster-repository>` and :ref:`Initialization (Proxmox) <quick-start.proxmox.create-and-initialize-cluster-repository>` (`!1560 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1560>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 83.4.0 to 84.3.0 (`!2453 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2453>`_)


New Features
~~~~~~~~~~~~

- Support for deploying Tarook on Proxmox has been added.

  See :doc:`/user/guide/quick-start/proxmox/index` for a first impression. (`!1560 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1560>`_, `!2484 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2484>`_)
- The following option has been introduced to easily configure the event TTL for the kube-apiserver:
  :ref:`configuration-options.yk8s.kubernetes.apiserver.event_ttl`. (`!2272 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2272>`_)
- Control plane components can now be customized using patches, see:

  * :ref:`configuration-options.yk8s.kubernetes.kubeadm.patches.corednsdeployment`
  * :ref:`configuration-options.yk8s.kubernetes.kubeadm.patches.etcd`
  * :ref:`configuration-options.yk8s.kubernetes.kubeadm.patches.kube-apiserver`
  * :ref:`configuration-options.yk8s.kubernetes.kubeadm.patches.kube-controller-manager`
  * :ref:`configuration-options.yk8s.kubernetes.kubeadm.patches.kube-scheduler`
  * :ref:`configuration-options.yk8s.kubernetes.kubeadm.patches.kubeletconfiguration`

  .. important::

     Patch files manually added to ``/etc/kubernetes/kubeadm-patches`` on a node
     will get **removed** on a rollout.

  For more information,
  refer to `kubeadm: Customizing with patches <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/#patches>`_ (`!2272 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2272>`_)
- The action :ref:`destroy.sh<actions-references.destroysh>` now supports bare-metal clusters (`!2273 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2273>`_)
- Support for Kubernetes v1.36 has been added. (`!2510 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2510>`_)


Changed Functionality
~~~~~~~~~~~~~~~~~~~~~

- We now check whether the currently used Nix version is supported before invoking any Nix commands. (`!1983 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1983>`_)
- Nvidia packages on a Kubernetes node with GPU capability
  are installed or updated only if the node has not been fully initialized yet
  or with explicit consent. (`!2455 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2455>`_)
- Triggering the :ref:`apply-k8s-supplements action <actions-references.apply-k8s-supplementssh>` does not implicitly trigger the :ref:`apply-k8s-core action <actions-references.apply-k8s-coresh>` anymore. (`!2461 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2461>`_)
- Runtime improvements have been made to the node system update logic of the
  :ref:`apply-k8s-core action <actions-references.apply-k8s-coresh>`. (`!2462 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2462>`_)
- In clusters with GPU worker nodes, the NVIDIA Container Runtime log level has been set to error.
  The change will be applied on a
  :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`
  or
  :ref:`system update<actions-references.update-kubernetes-nodessh>`. (`!2490 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2490>`_)
- Increased the timeout of the initial SSH connection check against each node
  from 5 minutes to 15
  in order to support nodes and/or IaaS environments with longer OS bring-up durations. (`!2492 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2492>`_)
- It is now required to configure gateway nodes
  when setting :ref:`configuration-options.yk8s.wireguard.enabled` to ``true``.
  Previously the option was silently ignored when no gateway nodes were present. (`!2495 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2495>`_)


Dependencies
~~~~~~~~~~~~

- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.6.0 to 4.8.1 (`!2296 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2296>`_)
- Updated default version of helm chart nvidia-device-plugin of https://github.com/NVIDIA/k8s-device-plugin from 0.18.2 to 0.19.3 (`!2379 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2379>`_)
- `!2418 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2418>`_, `!2449 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2449>`_, `!2451 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2451>`_, `!2458 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2458>`_, `!2471 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2471>`_, `!2473 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2473>`_, `!2480 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2480>`_, `!2498 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2498>`_, `!2499 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2499>`_, `!2505 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2505>`_, `!2512 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2512>`_, `!2518 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2518>`_, `!2520 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2520>`_, `!2521 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2521>`_, `!2533 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2533>`_, `!2537 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2537>`_
- Updated default version of helm chart etcdbackup from 2.0.2 to 2.0.3 (`!2444 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2444>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 83.4.0 to 83.7.0 (`!2450 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2450>`_)
- The upstream repository URL for the nvidia-container-toolkit has been updated
  sucht that Kubernetes workers with GPU capability can fetch the latest package versions.
  The package will be updated on a
  :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`
  or
  :ref:`system update<actions-references.update-kubernetes-nodessh>`. (`!2455 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2455>`_)
- The upstream repository URL for the Nvidia cuda drivers has been updated.
  The Nivida cuda drivers got bumped from 530 to 595.
  The packages will be updated on a
  :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`
  or
  :ref:`system update<actions-references.update-kubernetes-nodessh>`. (`!2455 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2455>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.9.1 to 11.9.2 (`!2470 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2470>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.9.2 to 11.10.0 (`!2474 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2474>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.8.1 to 4.8.2 (`!2475 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2475>`_)
- Updated default version of helm chart rook-ceph of https://github.com/rook/rook from v1.18.10 to v1.18.11 (`!2497 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2497>`_)
- Updated default version of helm chart etcdbackup from 2.0.3 to 2.3.0 (`!2502 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2502>`_)
- Updated default version of helm chart openstack-cinder-csi of https://github.com/kubernetes/cloud-provider-openstack from 2.35.0 to 2.36.0 (`!2503 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2503>`_)
- Updated default version of helm chart openstack-cloud-controller-manager of https://github.com/kubernetes/cloud-provider-openstack from 2.35.0 to 2.36.0 (`!2504 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2504>`_)
- The ``nixpkgs.url`` has been changed from 25.11 to 26.05. (`!2511 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2511>`_)
- Updated default version of helm chart etcdbackup from 2.3.0 to 2.3.1 (`!2517 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2517>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.10.0 to 11.12.0 (`!2519 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2519>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.12.0 to 11.13.0 (`!2523 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2523>`_)
- Updated default version of helm chart etcdbackup from 2.3.1 to 2.4.0 (`!2524 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2524>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 84.3.0 to 84.5.0 (`!2531 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2531>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.20.2 to v1.20.3 (`!2535 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2535>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.13.0 to 11.15.0 (`!2539 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2539>`_)


Bugfixes
~~~~~~~~

- A bug has been fixed that resulted in a deadlock when using both ``USE_VAULT_IN_DOCKER=true`` and ``YAOOK_K8S_DIRENV_MANUAL=true``. (`!2288 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2288>`_)
- Fixed the option names in a few warnings (`!2381 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2381>`_)
- Hostnames are now validated during inventory generation. (`!2454 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2454>`_)
- With the latest nvidia-container-toolkit a `bug <https://github.com/NVIDIA/nvidia-docker/issues/1730>`__ has been fixed
  which caused existing workload to lose access to the GPU
  on a ``systemctl daemon-reload``. (`!2455 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2455>`_)
- ``TAROOK_NIX_FLAGS`` (see :doc:`environment variables </user/reference/environmental-variables>`) now accepts multiple flags (`!2456 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2456>`_, `!2516 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2516>`_)
- A bug has been fixed where Grafana ignored Thanos datasource configuration changes. (`!2464 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2464>`_)
- Affinity and tolerations for the node feature discovery subchart of the nvidida-device-plugin have been fixed. (`!2467 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2467>`_)
- Affinity and tolerations for the CRD upgrade job of the kube-prometheus-stack have been fixed. (`!2467 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2467>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- We now provide a script to upgrade Nix on Debian-based systems to the version tested in our CI. The script can be run with ``nix run git+https://gitlab.com/alasca.cloud/tarook/nix#upgrade``. (`!1983 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1983>`_)
- Restructured Vault docs (`!2366 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2366>`_)
- Documented that Tarook only supports one cluster per OpenStack project (`!2443 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2443>`_)
- The description of :ref:`configuration-options.yk8s.openstack.network_mtu` has been refined. (`!2465 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2465>`_)
- Fixed the documented default values of some options. (`!2515 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2515>`_)
- Introduced a new release note category: Dependencies. (`!2534 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2534>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Support for Kubernetes v1.32 has been dropped. (`!2459 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2459>`_)
- The tasks which check for stale etcd peers have been removed.
  It is up to the user to ensure etcd peers are properly removed when reconfiguring the set of control plane nodes.
  This is ensured by running ``kubeadm reset`` on the node to be removed. (`!2460 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2460>`_)


Other Tasks
~~~~~~~~~~~

- Relocated all assertions in option apply functions to ``config.yk8s.assertions`` (`!2381 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2381>`_)
- Relocated all warnings in option apply functions to ``config.yk8s.warnings`` (`!2381 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2381>`_)
- Added warnings for
  :ref:`configuration-options.yk8s.infra.subnet_cidr`/:ref:`configuration-options.yk8s.infra.subnet_v6_cidr`
  being ignored if
  :ref:`configuration-options.yk8s.infra.ipv4_enabled`/:ref:`configuration-options.yk8s.infra.ipv6_enabled`
  is ``false``. (`!2381 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2381>`_)
- `!2522 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2522>`_, `!2541 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2541>`_


Misc
~~~~

- `!2425 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2425>`_, `!2479 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2479>`_, `!2485 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2485>`_, `!2494 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2494>`_, `!2534 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2534>`_, `!2543 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2543>`_
