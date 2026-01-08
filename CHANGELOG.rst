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

v11.0.4 (2026-01-08)
--------------------

Bugfixes
~~~~~~~~

- A bug was fixed that caused issues when the same option was set in multiple places #846 (`!2248 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2248>`_)


v11.0.3 (2025-12-09)
--------------------

Bugfixes
~~~~~~~~

- Fixed a bug which prevented the release migration script :ref:`migrate-to-release.sh<actions-references.migrate-to-releasesh>`
  from completing successfully with :ref:`Terraform disabled <configuration-options.yk8s.terraform.enabled>`. (`!2209 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2209>`_)
- Fixed a bug in the release migration that left new Terraform state uncommitted. (`!2209 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2209>`_)
- Fixed a bug which prevented to rerun the release migration script :ref:`migrate-to-release.sh<actions-references.migrate-to-releasesh>`. (`!2209 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2209>`_)


v11.0.2 (2025-10-23)
--------------------

Bugfixes
~~~~~~~~

- A bug in the migration script has been fixed that prevented use of Ansible playbooks directly after migration on OpenStack-based clusters. (`!2179 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2179>`_)
- Fixed the assertion that enforces either
  the new :ref:`configuration-options.yk8s.infra.ansible_hosts`
  or the old :ref:`configuration-options.yk8s.infra.hosts_file`
  option is set. (`!2179 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2179>`_)
- Fixed a Nix config error
  that prevented the use of :ref:`configuration-options.yk8s.infra.hosts_file`
  (when :ref:`Terraform is disabled <configuration-options.yk8s.terraform.enabled>`). (`!2179 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2179>`_)
- A bug has been fixed which prevented cluster creation or adding new nodes to an existing cluster if :ref:`configuration-options.yk8s.ch-k8s-lbaas.enable_snat` got disabled. (`!2179 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2179>`_)
- A bug has been fixed which caused :ref:`apply-prepare-gw.sh <actions-references.apply-prepare-gwsh>` to fail after reconfiguring :ref:`configuration-options.yk8s.ch-k8s-lbaas.enable_snat` until :ref:`apply-k8s-supplements.sh <actions-references.apply-k8s-supplementssh>` (more specifically the ``install-ch-k8s-lbaas.yaml`` playbook) has been executed. (`!2179 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2179>`_)
- A file permission bug in a migration script has been fixed (`!2179 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2179>`_)


Other Tasks
~~~~~~~~~~~

- `!2179 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2179>`_


v11.0.1 (2025-10-21)
--------------------

Bugfixes
~~~~~~~~

- A bug in the migration script has been fixed (`!2175 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2175>`_)


v11.0.0 (2025-10-17)
--------------------

Breaking changes
~~~~~~~~~~~~~~~~

- Updated default version of helm chart prometheus-adapter of https://github.com/prometheus-community/helm-charts from 4.14.2 to 5.0.0 (`!1997 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1997>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 73.2.3 to 77.0.0 (`!2058 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2058>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 77.12.0 to 78.2.1 (`!2156 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2156>`_)


New Features
~~~~~~~~~~~~

- Ansible hosts can now be defined and referenced via Nix. See :ref:`configuration-options.yk8s.infra.ansible_hosts`. (`!1250 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1250>`_)
- The helm chart for etcd-backup can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values`. (`!1569 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1569>`_)
- The helm chart url, name and version can now be configured for the nvidia device plugin through :ref:`yk8s.nvidia.device_plugin.helm <configuration-options.yk8s.nvidia>`. (`!1784 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1784>`_)
- The helm chart for the Nvidia device plugin can now be configured with arbitrary values through :ref:`configuration-options.yk8s.nvidia.device_plugin.helm.values`. (`!1784 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1784>`_)
- The helm chart for ingress-nginx can now be configured with arbitrary values through :ref:`configuration-options.yk8s.k8s-service-layer.ingress.helm.values`. (`!1810 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1810>`_)
- An option to disable SNAT'ing for :doc:`ch-k8s-lbaas </user/explanation/services/ch-k8s-lbaas>` has been added:
  :ref:`configuration-options.yk8s.ch-k8s-lbaas.enable_snat`.

  .. warning::

    Be aware that disabling SNAT'ing potentially has performance implications.
    Have a look at :ref:`configuration-options.yk8s.ch-k8s-lbaas.enable_snat` for further information.

  .. warning::

    Disabling :ref:`configuration-options.yk8s.ch-k8s-lbaas.enable_snat` can only be done after the release migration
    including executing :ref:`apply-all.sh <actions-references.apply-allsh>` has been finished.

  . (`!1943 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1943>`_)
- The functionality of :ref:`configuration-options.yk8s.kubernetes.apiserver.audit_logs.enabled` has been refined such that the settings take effect on cluster initialization already and modifications to the settings are not applied during Kubernetes upgrades only but on normal rollouts. The settings are also reflected in the ``kube-system/kubeadm-config`` ConfigMap in the cluster now which ensures freshly provisioned control-plane nodes have the setting right away. (`!1956 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1956>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Updated default version of helm chart flux2 of https://github.com/fluxcd-community/helm-charts from 2.9.2 to 2.15.0

  .. warning::

      This upgrades the Flux controllers from app version 2.0.1 to 2.5.1.
      You potentially have to adjust your deployed custom resources.
      Check the changelog for API adjustments:

      * https://github.com/fluxcd/flux2/releases/tag/v2.1.0
      * https://github.com/fluxcd/flux2/releases/tag/v2.2.0
      * https://github.com/fluxcd/flux2/releases/tag/v2.3.0
      * https://github.com/fluxcd/flux2/releases/tag/v2.4.0
      * https://github.com/fluxcd/flux2/releases/tag/v2.5.0

      You can upgrade more fine grained by setting the desired version via :ref:`configuration-options.yk8s.k8s-service-layer.fluxcd.version`.

      Further information can be found in the `Flux releases documentation <https://fluxcd.io/flux/releases/>`_.

  . (`!1698 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1698>`_)
- Updated default version of helm chart rook-ceph of https://github.com/rook/rook from v1.16.6 to v1.17.8 (`!1816 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1816>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.3.0 to 11.3.1 (`!2061 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2061>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.13.1 to 4.13.2 (`!2070 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2070>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 77.0.0 to 77.2.0 (`!2081 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2081>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 77.2.0 to 77.3.0 (`!2087 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2087>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 77.3.0 to 77.8.0 (`!2117 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2117>`_)
- The peering mechanism of keepalived has been changed from explicit unicast back to multicast. (`!2118 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2118>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 77.8.0 to 77.9.1 (`!2119 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2119>`_)
- The bucket management tasks have been dropped for :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup`.
  It is now the user's responsibility to ensure the bucket exists.
  Documentation has been updated accordingly.
  Existing buckets are not touched. (`!2120 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2120>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.5.0 to 4.5.2 (`!2121 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2121>`_)
- Unattended upgrades are enabled on gateways now. (`!2126 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2126>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 77.9.1 to 77.11.0 (`!2133 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2133>`_)
- Updated default version of helm chart prometheus-adapter of https://github.com/prometheus-community/helm-charts from 5.0.0 to 5.1.0 (`!2138 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2138>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 77.11.0 to 77.11.1 (`!2140 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2140>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 77.11.1 to 77.12.0 (`!2141 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2141>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.3.1 to 11.4.0 (`!2154 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2154>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.13.2 to 4.13.3 (`!2158 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2158>`_)
- Updated default version of helm chart etcdbackup from 0.20250724.0 to 0.20250918.0 (`!2160 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2160>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.4.0 to 11.4.1 (`!2163 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2163>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.18.2 to v1.18.3 (`!2166 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2166>`_)


Bugfixes
~~~~~~~~

- The type of :ref:`configuration-options.yk8s.kubernetes.apiserver.audit_logs.policy` has been changed such that individual values can be overwritten. (`!1956 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1956>`_)
- A bug has been fixed which prevented to deploy rook-ceph in a different namespace than the default: :ref:`configuration-options.yk8s.k8s-service-layer.rook.namespace`. (`!1998 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1998>`_)
- Ansible and Helm now don't try to use user-wide (cache) directories anymore. (`!2051 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2051>`_)
- Darwin as well as Linux on aarch64 are not supported by Tarook. Thus, they have been removed from the list of supported systems. (`!2067 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2067>`_)
- Fixed the ``vault_v1`` Ansible role
  to deploy the vault-backup ServiceMonitor
  only when monitoring is enabled via :ref:`configuration-options.yk8s.kubernetes.monitoring.enabled`. (`!2069 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2069>`_)
- Adjust review link to new url (`!2085 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2085>`_)
- Fixed an issue where regex validation of IP patterns did not work on macOS hosts. (`!2104 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2104>`_)
- Deploying Vault on Kubernetes through :ref:`configuration-options.yk8s.k8s-service-layer.vault`
  requires cert-manager
  which is now documented and enforced at config evaluation. (`!2114 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2114>`_)
- Fixed a bug which prevented etcd-backup to be deployed in a modified namespace: :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.release_namespace`. (`!2122 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2122>`_)
- The ``.gitignore`` file of the cluster repository now includes the 'managed by yk8s' markers
  from cluster repo initialization already,
  not just after the first release migration. (`!2131 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2131>`_)
- SSH host certificates are now always generated using the ``yaook/nodes`` Vault approle.
  Previously the orchestrator's credentials were used
  when ``USE_VAULT_IN_DOCKER=true`` (see :doc:`/developer/explanation/vault`) was set
  which prevented the use of unpriviledged Vault tokens. (`!2132 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2132>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- A note that ``nix (Nix) >= 2.9.0`` is required has been added to :doc:`user/guide/quick-start/initialization`. (`!2063 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2063>`_)
- Documentation generation is restricted to the latest five major versions from now on. (`!2102 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2102>`_)
- Merged the tutorials into the guides section (`!2130 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2130>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Importing an existing hosts file via :ref:`configuration-options.yk8s.infra.hosts_file` is deprecated. Hosts can be defined directly via Nix now. The option ``hosts_file`` will be removed at some point in the future. If you want to keep providing your own hosts file after that, convert it to YAML format (see https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html ) and import it like this ``ansible_hosts = yk8s-libs.importYAML ./hosts;``. (`!1250 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1250>`_)


Other Tasks
~~~~~~~~~~~

- `!1748 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1748>`_, `!1915 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1915>`_, `!1943 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1943>`_, `!1943 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1943>`_, `!2071 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2071>`_, `!2072 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2072>`_, `!2083 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2083>`_, `!2084 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2084>`_, `!2101 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2101>`_, `!2105 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2105>`_, `!2111 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2111>`_, `!2113 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2113>`_, `!2115 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2115>`_, `!2124 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2124>`_, `!2128 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2128>`_, `!2142 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2142>`_, `!2148 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2148>`_, `!2149 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2149>`_, `!2155 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2155>`_
- The ``build-docs-check`` CI job now uses Nix to build the documentation. (`!2075 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2075>`_)
- Container images for smoke tests have been updated. (`!2112 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2112>`_)


Misc
~~~~

- `!2004 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2004>`_, `!2065 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2065>`_, `!2066 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2066>`_, `!2096 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2096>`_, `!2100 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2100>`_, `!2103 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2103>`_, `!2125 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2125>`_, `!2129 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2129>`_, `!2137 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2137>`_, `!2143 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2143>`_, `!2144 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2144>`_, `!2146 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2146>`_, `!2157 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2157>`_, `!2164 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2164>`_, `!2165 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2165>`_
