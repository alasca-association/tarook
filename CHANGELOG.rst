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

v15.0.0 (2026-09-28)
--------------------

Breaking Changes
~~~~~~~~~~~~~~~~

- Calico is now deployed in eBPF mode. For existing deployments running in iptables, ipvs or nftables mode, this is disruptive.

  Run ``MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/apply-k8s-supplements.sh install-calico.yaml`` to perform the migration. (`!2577 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2577>`_)
- The option ``yk8s.state_directory`` has been removed, so the assignment must be removed from ``flake.nix``. The migration script will try to handle that and in case of failure provide the manual migration steps. (`!2582 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2582>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 84.5.0 to 91.2.1 (`!2642 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2642>`_)


New Features
~~~~~~~~~~~~

- The helm chart for nvidia-dcgm-exporter can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter.helm.values`. (`!1501 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1501>`_)
- The helm chart for blackbox-exporter can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.blackbox_exporter.helm.values`. (`!1501 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1501>`_)
- The helm chart for Thanos can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos.helm.values`. (`!1501 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1501>`_)
- The helm chart for prometheus-adapter can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_adapter.helm.values`. (`!1501 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1501>`_)
- The helm chart for kube-prometheus-stack can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.helm.values`. (`!1501 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1501>`_)
- Support for Debian 13 (Trixie) for gateway nodes in clusters running on Openstack or Proxmox has been added.
  The BIRD setup has been made compatible with version 3. (`!2477 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2477>`_)
- The default for :ref:`configuration-options.yk8s.kubernetes.network.bgp_announce_service_ips` has been changed from ``false`` to ``true``
  such that routes to the Kubernetes Service IP range are announced to gateway nodes by default. (`!2477 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2477>`_)
- Envoy Gateway can now be installed as a supplement.

  To do so, set :ref:`configuration-options.yk8s.k8s-service-layer.envoy-gateway.enabled` and run ``./managed-k8s/actions/apply-k8s-supplements.sh install-envoy-gateway.yaml``.

  .. note::

     If you've previously used Gateway API with Tigera, this change is disruptive and you'll need to provide ``MANAGED_K8S_RELEASE_THE_KRAKEN=true``.


  .. important::

     The migration may take several (5-10) minutes during which workload is not reachable via the Gateway.

  .. important::

     Existing Gateways may end up with a different external IP address after the migration. If you want to keep the address, manual steps are necessary that depend on the LBaaS in use and are not covered here.

  .. important::

     The ``GatewayClass`` ``tigera-gateway-class`` may be lost during the migration. If so, existing Gateways must be adapted to reference the newly created ``envoy-gateway`` ``GatewayClass``.

  (`!2564 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2564>`_)
- kube-proxy can now be disabled, see :ref:`configuration-options.yk8s.kubernetes.network.kube_proxy.enabled` (`!2577 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2577>`_)
- :ref:`update-inventory.sh <actions-references.update-inventorysh>` now prints used Nix versions to make debugging easier. (`!2655 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2655>`_)


Changed Functionality
~~~~~~~~~~~~~~~~~~~~~

- The CI/CD pipeline now uses Debian 13 images for gateway nodes. (`!2477 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2477>`_)
- Since Tarook supports Gateway API (via Envoy),
  cert-manager's integration for it will be enabled alongside by default. (`!2493 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2493>`_)
- The Calico network MTU for OpenStack has been reduced by the VXLAN overhead to
  ensure NodePort traffic can be forward between nodes without packet fragmentation. (`!2641 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2641>`_)
- Support for tlsConfig blocks in kube-prometheus-stack Helm chart >= 90.0.0 has been enabled. (`!2643 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2643>`_)
- The ``sntrup761x25519-sha512`` post-quantum key exchange algorithm for SSH server has been enabled. (`!2650 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2650>`_)


Dependencies
~~~~~~~~~~~~

- Updated default version of helm chart tigera-operator of https://github.com/projectcalico/calico from v3.31.5 to v3.32.1.

  .. warning::

     Starting with v3.32.0 custom NetworkPolicies are introduced by the tigera-operator
     which prevent scraping of metrics of calico-kube-controllers by default.
     A workaround has been implemented. Please ensure a full rollout of
     :ref:`apply-k8s-supplements.sh <actions-references.apply-k8s-supplementssh>` is done.

  _ (`!2466 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2466>`_)
- Updated default version of helm chart tigera-operator of https://github.com/projectcalico/calico from v3.31.5 to v3.31.7 (`!2525 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2525>`_, `!2616 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2616>`_)
- The default version of :ref:`configuration-options.yk8s.containerd.version` has been bumped from 2.1.5 to 2.3.5. (`!2527 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2527>`_, `!2654 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2654>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.15.0 to 11.18.0 (`!2542 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2542>`_, `!2593 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2593>`_, `!2623 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2623>`_)
- The Ansible Galaxy collection ansible.posix has been updated from 2.2.0 to 2.2.1 (`!2544 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2544>`_)
- `!2549 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2549>`_, `!2556 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2556>`_, `!2557 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2557>`_, `!2566 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2566>`_, `!2580 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2580>`_, `!2590 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2590>`_, `!2600 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2600>`_, `!2604 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2604>`_, `!2612 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2612>`_, `!2613 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2613>`_, `!2622 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2622>`_, `!2625 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2625>`_, `!2653 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2653>`_
- The Ansible Galaxy collection kubernetes.core has been updated from 6.4.0 to 6.6.0 (`!2552 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2552>`_, `!2647 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2647>`_)
- Introduced automated release notes for Ansible Galaxy collection updates. (`!2562 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2562>`_)
- Release notes for renovate updates of
  :ref:`configuration-options.yk8s.containerd.version`
  and
  :ref:`configuration-options.yk8s.kubernetes.version`
  now include a reference to the configuration options. (`!2562 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2562>`_)
- The Ansible Galaxy collection community.general has been updated from 13.1.0 to 13.4.0 (`!2565 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2565>`_, `!2603 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2603>`_, `!2632 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2632>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.8.2 to 4.8.3 (`!2570 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2570>`_)
- The default version of :ref:`configuration-options.yk8s.kubernetes.version` has been bumped from v1.36.2 to v1.36.4. (`!2587 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2587>`_, `!2610 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2610>`_)
- Updated default version of helm chart openstack-cloud-controller-manager of https://github.com/kubernetes/cloud-provider-openstack from 2.36.0 to 2.36.5 (`!2589 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2589>`_, `!2619 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2619>`_, `!2631 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2631>`_, `!2635 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2635>`_)
- Updated default version of helm chart openstack-cinder-csi of https://github.com/kubernetes/cloud-provider-openstack from 2.36.0 to 2.36.5 (`!2595 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2595>`_, `!2597 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2597>`_, `!2629 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2629>`_, `!2633 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2633>`_, `!2634 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2634>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.20.3 to v1.20.4 (`!2648 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2648>`_)


Bugfixes
~~~~~~~~

- The git protocol is now used for Flake inputs in order to avoid GitHub API rate limits. (`!2551 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2551>`_, `!2608 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2608>`_)
- Fixed the error handling of the SSH user detection
  so that failure is handled gracefully.

  The error message now includes failure details. (`!2568 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2568>`_)
- The :ref:`apply-prepare-gw.sh action <actions-references.apply-prepare-gwsh>` does not fail anymore if
  :ref:`configuration-options.yk8s.wireguard.enabled` is set to ``false``. (`!2569 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2569>`_)
- Fixed incorrect config warnings for memory request and limits. (`!2571 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2571>`_)
- The :ref:`destroy.sh <actions-references.destroysh>` action now ensures that OpenStack volumes are detached before attempting to delete them. (`!2572 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2572>`_)
- A bug has been fixed that didn't allow updates in the Calico settings to apply. (`!2577 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2577>`_)
- Fixed invalid Terraform JSON syntax for OpenStack anti-affinity groups, which caused :ref:`apply-terraform.sh <actions-references.apply-terraformsh>`
  to fail when :ref:`configuration-options.yk8s.openstack.nodes.<name>.anti_affinity_group` was set. (`!2607 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2607>`_)
- A rollout now fails if not all calico-apiservers get ready. (`!2626 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2626>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- A guideline for writing comments has been added to the :ref:`Coding Guide <coding-guide.comments>`. (`!2581 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2581>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Removed support for IPSec after it has been deprecated since release v10.0.0.

  .. attention:: Potential action required

     In case you still have IPSec enabled (``config.yk8s.ipsec.enabled = true``),
     you need to undeploy it **before** upgrading to this release.

     .. code:: console

        $ edit config/default.nix  # set `config.yk8s.ipsec.enabled = false`
        $ VAULT_TOKEN=${vault_root_token:?} ./managed-k8s/actions/apply-prepare-gw.sh
        ......
        $ edit config/default.nix  # remove `config.yk8s.ipsec.*`
        $

  _ (`!2382 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2382>`_)
- The option ``yk8s.kubernetes.network.calico.values_file_path`` has been removed. Please use :ref:`configuration-options.yk8s.kubernetes.network.calico.helm.values` instead. (`!2577 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2577>`_)


Other Tasks
~~~~~~~~~~~

- `!2663 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2663>`_


Misc
~~~~

- `!2573 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2573>`_, `!2579 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2579>`_, `!2583 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2583>`_, `!2592 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2592>`_, `!2605 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2605>`_, `!2606 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2606>`_, `!2618 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2618>`_, `!2640 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2640>`_
