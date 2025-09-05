Releasenotes
============

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.0.0/>`__,
and this project will adhere to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`__.

We use `towncrier <https://github.com/twisted/towncrier>`__ for the
generation of our release notes file.

Information about unreleased changes can be found
`here <https://gitlab.com/yaook/k8s/-/tree/devel/docs/_releasenotes?ref_type=heads>`__.

.. towncrier release notes start

v10.0.6 (2025-09-05)
--------------------

Bugfixes
~~~~~~~~

- k8s-login run in :doc:`root CA rotation </user/guide/vault/vault-ca-rotation>` phase 1
  works again with a Vault token only having the ``yaook/orchestrator`` policy.
  (regression of v10.0.0)

  .. note:: Action needed

     To activate the fix the Vault orchestrator policy needs to be updated.

     .. code:: shell

        VAULT_TOKEN=$vault_root_token ./managed-k8s/tools/vault/init.sh

  _ (`!2098 <https://gitlab.com/yaook/k8s/-/merge_requests/2098>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Changelogs of previous releases have been dropped.
  These are still accessible when switching to the respective version.
  From now on, changelogs for each version will be maintained separately and not continously. (`!2098 <https://gitlab.com/yaook/k8s/-/merge_requests/2098>`_)


Misc
~~~~

- `!2098 <https://gitlab.com/yaook/k8s/-/merge_requests/2098>`_


v10.0.5 (2025-08-26)
--------------------

New Features
~~~~~~~~~~~~

- The following modules of :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module` now do also accept the HTTP status code ``400``:

  * ``http_api_v6``
  * ``http_api_insecure_v6``
  * ``http_api``
  * ``http_api_insecure``

  . (`!2053 <https://gitlab.com/yaook/k8s/-/merge_requests/2053>`_)


Bugfixes
~~~~~~~~

- Allow to configure IPv6-specific modules for blackbox-exporter probes in :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module`.
  Although these modules have been introduced in v9.1.0, they could not be configured until now. (`!2053 <https://gitlab.com/yaook/k8s/-/merge_requests/2053>`_)
- Fixed the type of :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_objectstorage_container_name`
  (regression of v10.0.0) (`!2053 <https://gitlab.com/yaook/k8s/-/merge_requests/2053>`_)
- Fixed the type of :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.file_prefix`
  (regression of v10.0.0) (`!2053 <https://gitlab.com/yaook/k8s/-/merge_requests/2053>`_)
- Fixed the type of :ref:`configuration-options.yk8s.infra.cluster_name`
  (regression of v10.0.0) (`!2053 <https://gitlab.com/yaook/k8s/-/merge_requests/2053>`_)


Misc
~~~~

- `!2053 <https://gitlab.com/yaook/k8s/-/merge_requests/2053>`_


v10.0.4 (2025-08-19)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The Thanos image repository has been set to ``bitnamilegacy/thanos`` due to `recent changes by the Bitnami offering <https://github.com/bitnami/containers/issues/83267>`_. (`!1990 <https://gitlab.com/yaook/k8s/-/merge_requests/1990>`_)


v10.0.3 (2025-08-13)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The project has been renamed from YAOOK/K8s to TAROOK.
  The repository location has been updated to reflect this change. (`!1870 <https://gitlab.com/yaook/k8s/-/merge_requests/1870>`_)


Bugfixes
~~~~~~~~

- The :ref:`release migration script <actions-references.migrate-to-releasesh>`
  now stages (and commits) its updates to a cluster repo's gitignore. (`!1999 <https://gitlab.com/yaook/k8s/-/merge_requests/1999>`_)
- The :ref:`release migration script <actions-references.migrate-to-releasesh>`
  does not output expected and misleading ``git apply`` errors anymore. (`!1999 <https://gitlab.com/yaook/k8s/-/merge_requests/1999>`_)


Other Tasks
~~~~~~~~~~~

- `!1999 <https://gitlab.com/yaook/k8s/-/merge_requests/1999>`_


v10.0.2 (2025-08-05)
--------------------

Bugfixes
~~~~~~~~

- Cluster setup for IPv6-only clusters has been fixed. (`!1977 <https://gitlab.com/yaook/k8s/-/merge_requests/1977>`_)


v10.0.1 (2025-07-31)
--------------------

Bugfixes
~~~~~~~~

- Fixed a bug in the ``vault_v1`` Ansible role that let the role fail
  when the value of :ref:`configuration-options.yk8s.k8s-service-layer.vault.backup_approle_path`
  did not end with a forward slash.
  With release v10.0.0 this failure became unavoidable
  because since then the config option's value must not end with a slash anymore. (`!1974 <https://gitlab.com/yaook/k8s/-/merge_requests/1974>`_)
- :ref:`configuration-options.yk8s.k8s-service-layer.vault.s3_config_file`
  is not forced to be set anymore. (regression of v10.0.0) (`!1974 <https://gitlab.com/yaook/k8s/-/merge_requests/1974>`_)


v10.0.0 (2025-07-26)
--------------------

Breaking changes
~~~~~~~~~~~~~~~~

- The VIP port IP address and the gateway port IDs are now added to the
  ch-k8s-lbaas configuration (``./k8s-supplements/ansible/roles/ch-k8s-lbaas-controller/templates/controller-config.toml``)
  which is required as we re-introduced OpenStack security groups which are
  needed in OpenStack environments which use OVN.

  From now on, ch-k8s-lbaas must know the OpenStack port id for its configuration.
  The port id is added to the hosts file by Terraform automatically.
  Terraform therefore has to be triggered once and the ch-k8s-lbaas setup must be updated.

  The :ref:`actions-references.migrate-to-releasesh` script takes care of all the necessary steps:

  .. code:: console

    $ bash managed-k8s/actions/migrate-to-release.sh

  .. attention::

     Note that ch-k8s-lbaas' config must be updated
     immediately after Terraform updated the harbour infrastructure
     in order to not interrupt the cluster's internet connectivity.
     Therefore, if you have :ref:`configuration-options.yk8s.ch-k8s-lbaas.enabled` set,
     make sure the migration script completes both actions
     in quick succession.

  _ (`!1250 <https://gitlab.com/yaook/k8s/-/merge_requests/1250>`_)
- The LCM now supports OVN-based OpenStack environments.
  That required to reintroduce OpenStack security groups
  and to enable port security on the gateway ports.

  Furthermore, if
  :ref:`configuration-options.yk8s.ch-k8s-lbaas.enabled`
  is enabled,
  :ref:`configuration-options.yk8s.ch-k8s-lbaas.version`
  must be set to ``0.8.0`` or higher.

  .. hint::

    Note that it is recommended to not explicitly pin ch-k8s-lbaas to a specific version
    because then it is automatically updated once support
    for a new version has been added.

  There may be connectivity issues with load-balanced services
  managed by ch-k8s-lbaas starting with the
  completion of the Terraform stage until a rollout fully finished.
  This is because port security on the gateway ports has been reenabled,
  but the ch-k8s-lbaas agents are not aware about that, yet.
  If :ref:`configuration-options.yk8s.ch-k8s-lbaas.enabled` is set to ``true``,
  it is highly recommended to update its version in advance
  to the Terraform stage to reduce impact.

  The :ref:`actions-references.migrate-to-releasesh` script takes care of all the necessary steps:

  .. code:: console

    $ bash managed-k8s/actions/migrate-to-release.sh

  A full rollout is recommended but not mandatory:

  .. code:: console

    $ bash managed-k8s/actions/apply-all.sh

  . (`!1250 <https://gitlab.com/yaook/k8s/-/merge_requests/1250>`_)
- The following legacy options have been removed as they had no effect in recent versions,
  aren't documented well and it is currently not intended to support the use cases they once served:

  * ``yk8s.miscellaneous.docker_insecure_registries``
  * ``yk8s.miscellaneous.container_mirror_default_host``
  * ``yk8s.miscellaneous.configure_mirror_ca``

  Mirrors can be configured via :ref:`configuration-options.yk8s.containerd.mirrors` now. (`!1613 <https://gitlab.com/yaook/k8s/-/merge_requests/1613>`_)
- The option ``yk8s.miscellaneous.container_mirrors`` has been removed.
  Mirrors can be configured via :ref:`configuration-options.yk8s.containerd.mirrors` now. (`!1613 <https://gitlab.com/yaook/k8s/-/merge_requests/1613>`_)
- A new envrc layout for YAOOK/K8s has been added.


  .. attention:: Action required

      Run the migration script to ensure the layout is used

      .. code::

        ./managed-k8s/actions/migrate-to-release.sh

  . (`!1694 <https://gitlab.com/yaook/k8s/-/merge_requests/1694>`_)
- The obsolete option ``yk8s.load-balancing.priorities`` has been removed. (`!1717 <https://gitlab.com/yaook/k8s/-/merge_requests/1717>`_)
- The obsolete option ``yk8s.miscellaneous.wireguard_on_workers`` has been removed. (`!1717 <https://gitlab.com/yaook/k8s/-/merge_requests/1717>`_)
- The options to configure a wireguard endpoint directly under :ref:`configuration-options.yk8s.wireguard` have been removed. Please use :ref:`configuration-options.yk8s.wireguard.endpoints` instead. (`!1717 <https://gitlab.com/yaook/k8s/-/merge_requests/1717>`_)
- The :ref:`configuration-options.yk8s.ipsec.remote_private_addrs` config option
  expects a list now
  instead of a non-empty string previously.

  .. attention:: Action required

     If you use this option in your config, you must convert its value.

  _ (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- :ref:`configuration-options.yk8s.k8s-service-layer.vault.s3_config_file` defaults to ``null`` now. (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- The following config options now accept a Nix path
  instead of a file path string
  (e.g. ``"path/file"`` → ``./path/file``).

  - :ref:`configuration-options.yk8s.kubernetes.network.calico.values_file_path`

  _ (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- The :ref:`configuration-options.yk8s.miscellaneous.no_proxy` config option
  expects a list now
  instead of a comma separated list (string) previously.

  .. attention:: Action required

     If you use this option in your config, you must convert its value.

  _ (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- The release migration script has been renamed to better reflect its actions. (`!1738 <https://gitlab.com/yaook/k8s/-/merge_requests/1738>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 66.7.1 to 70.0.2 (`!1739 <https://gitlab.com/yaook/k8s/-/merge_requests/1739>`_)
- Since we recommend that
  ``etc/admin.conf`` should not be checked into version control,
  it has been added to the LCM managed gitignore rules.

  If your automation relies on ``etc/admin.conf``
  being checked into version control
  you may override the LCM's gitignore rules.

  .. attention:: Action required

      You must run the migration script to ensure that
      the cluster repo's ``.gitignore`` is updated.

      .. code::

        ./managed-k8s/actions/migrate-cluster-repo.sh
        # optionally, if you already committed etc/admin.conf
        git rm --cached etc/admin.conf

  _ (`!1787 <https://gitlab.com/yaook/k8s/-/merge_requests/1787>`_)
- Running the release migration script
  now inserts and updates the LCM's gitignore rules
  in the cluster repo's gitignore file.
  You may override them if needed.

  It is recommended to apply the cluster repo's gitignore rules to its git index
  with *every* major release.
  The following will remove any committed but gitignored file from version control:

  .. code:: shell

     git ls-files --ignored --cached --exclude-from=.gitignore -z \
       | xargs --no-run-if-empty --null git rm --cached -r

  _ (`!1789 <https://gitlab.com/yaook/k8s/-/merge_requests/1789>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 15.14.1 to 16.0.2 (`!1798 <https://gitlab.com/yaook/k8s/-/merge_requests/1798>`_)
- The option ``yk8s.kubernetes.network.plugin`` has been removed. Use :ref:`configuration-options.yk8s.kubernetes.network.calico.enabled` instead. (`!1836 <https://gitlab.com/yaook/k8s/-/merge_requests/1836>`_)
- The option ``yk8s.terraform.prevent_disruption`` has been removed. Preventing disruption is now handled by a lock file in the Terraform state directory. (`!1841 <https://gitlab.com/yaook/k8s/-/merge_requests/1841>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 70.10.0 to 72.0.0 (`!1846 <https://gitlab.com/yaook/k8s/-/merge_requests/1846>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 72.9.1 to 73.1.0 (`!1881 <https://gitlab.com/yaook/k8s/-/merge_requests/1881>`_)
- The option ``yk8s.kubernetes.apiserver.audit_logs.custom_policy`` has been removed.
  Use :ref:`configuration-options.yk8s.kubernetes.apiserver.audit_logs.policy` instead. (`!1896 <https://gitlab.com/yaook/k8s/-/merge_requests/1896>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 9.8.0 to 11.0.0 (`!1903 <https://gitlab.com/yaook/k8s/-/merge_requests/1903>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 16.0.7 to 17.2.0 (`!1908 <https://gitlab.com/yaook/k8s/-/merge_requests/1908>`_)


New Features
~~~~~~~~~~~~

- The feature to configure mirrors for containerd has been re-added.
  Mirrors can be configured via :ref:`configuration-options.yk8s.containerd.mirrors` now. (`!1613 <https://gitlab.com/yaook/k8s/-/merge_requests/1613>`_)
- Support for Kubernetes v1.32 has been added. (`!1880 <https://gitlab.com/yaook/k8s/-/merge_requests/1880>`_)
- A new env var ``TAROOK_NIX_FLAGS`` has been introduced: :ref:`Behavior-altering variables <environmental-variables.behavior-altering-variables>`.

  It can be used to supply additional flags to the ``nix build`` process of :ref:`update-inventory.sh<actions-references.update-inventorysh>`. (`!1898 <https://gitlab.com/yaook/k8s/-/merge_requests/1898>`_)
- If :ref:`configuration-options.yk8s.ch-k8s-lbaas.enabled` is set to ``true``, its keepalived VRRP instance is grouped with the VRRP instances of the VIP and VIP_v6 to ensure all instances are in consistent states. (`!1916 <https://gitlab.com/yaook/k8s/-/merge_requests/1916>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The Wireguard MTU is now conditionally set on the server and on the client side.
  It is clipped to a maximum of 1492 which is the maximum of a usual DSL connection.

  It is recommended to update the Wireguard client templates by executing:

  .. code:: console

    $ AFLAGS="--diff -t wireguard" bash managed-k8s/actions/apply-prepare-gw.sh

  . (`!1250 <https://gitlab.com/yaook/k8s/-/merge_requests/1250>`_)
- The keepalived peering mechanism has been changed to peer frontend nodes directly via unicast instead of multicast.
  For single-frontend-node setups, it automatically falls back to multicast as otherwise keepalived goes into an error state.

  It is recommended to update its configuration.

  The :ref:`actions-references.migrate-to-releasesh` script takes care of all the necessary steps:

  .. code:: console

    $ bash managed-k8s/actions/migrate-to-release.sh

  . (`!1250 <https://gitlab.com/yaook/k8s/-/merge_requests/1250>`_)
- The variable ``on_openstack`` is obsolete. If you're providing your own hosts file for a bare-metal cluster, you may remove the variable from it. (`!1718 <https://gitlab.com/yaook/k8s/-/merge_requests/1718>`_)
- The types of almost all config options have been refined to be more strict
  (no additional action necessary). (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- All config options that accept port numbers
  emit a warning for port 0. (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- Config options that accept a list of both IPv4 and IPv6 items
  now do ignore items of any IP family that is disabled
  so that they are not rendered into the Ansible inventory. (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- The :ref:`configuration-options.yk8s.load-balancing.deprecated_nodeport_lb_test_port` config option
  rejects port 0 now. (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 9.3.0 to 9.4.0 (`!1746 <https://gitlab.com/yaook/k8s/-/merge_requests/1746>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator/ from 0.20250227.0 to 0.20250324.1 (`!1766 <https://gitlab.com/yaook/k8s/-/merge_requests/1766>`_)
- Updated default version of helm chart rook-ceph of https://github.com/rook/rook from v1.16.5 to v1.16.6 (`!1773 <https://gitlab.com/yaook/k8s/-/merge_requests/1773>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 70.0.2 to 70.3.0 (`!1780 <https://gitlab.com/yaook/k8s/-/merge_requests/1780>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 15.13.2 to 15.14.0 (`!1783 <https://gitlab.com/yaook/k8s/-/merge_requests/1783>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 70.3.0 to 70.4.1 (`!1785 <https://gitlab.com/yaook/k8s/-/merge_requests/1785>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 15.14.0 to 15.14.1 (`!1786 <https://gitlab.com/yaook/k8s/-/merge_requests/1786>`_)
- We are now using packages from NixOS stable (`!1791 <https://gitlab.com/yaook/k8s/-/merge_requests/1791>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 70.4.1 to 70.4.2 (`!1794 <https://gitlab.com/yaook/k8s/-/merge_requests/1794>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.0.4 to 4.1.0 (`!1797 <https://gitlab.com/yaook/k8s/-/merge_requests/1797>`_)
- Updated default version of helm chart prometheus-adapter of https://github.com/prometheus-community/helm-charts from 4.13.0 to 4.14.1 (`!1799 <https://gitlab.com/yaook/k8s/-/merge_requests/1799>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 16.0.2 to 16.0.3 (`!1800 <https://gitlab.com/yaook/k8s/-/merge_requests/1800>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 70.4.2 to 70.5.0 (`!1814 <https://gitlab.com/yaook/k8s/-/merge_requests/1814>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 70.5.0 to 70.7.0 (`!1819 <https://gitlab.com/yaook/k8s/-/merge_requests/1819>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 16.0.3 to 16.0.4 (`!1823 <https://gitlab.com/yaook/k8s/-/merge_requests/1823>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.17.1 to v1.17.2 (`!1825 <https://gitlab.com/yaook/k8s/-/merge_requests/1825>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 70.7.0 to 70.8.0 (`!1826 <https://gitlab.com/yaook/k8s/-/merge_requests/1826>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 9.4.0 to 9.5.0 (`!1827 <https://gitlab.com/yaook/k8s/-/merge_requests/1827>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 70.8.0 to 70.10.0 (`!1833 <https://gitlab.com/yaook/k8s/-/merge_requests/1833>`_)
- The option ``yk8s.kubernetes.storage.cinder_enable_topology`` has been moved to :ref:`configuration-options.yk8s.openstack.cinder_enable_topology` (`!1834 <https://gitlab.com/yaook/k8s/-/merge_requests/1834>`_)
- The option ``yk8s.kubernetes.storage.rook_enabled`` has been moved to :ref:`configuration-options.yk8s.k8s-service-layer.rook.enabled` (`!1834 <https://gitlab.com/yaook/k8s/-/merge_requests/1834>`_)
- The default value for :ref:`configuration-options.yk8s.k8s-service-layer.ingress.replica_count` has been increased to ``2`` in order to reduce the chance of interruptions for accepting new connections during Kubernetes upgrades and the like. (`!1835 <https://gitlab.com/yaook/k8s/-/merge_requests/1835>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator from 0.20250324.1 to 0.20250429.0 (`!1837 <https://gitlab.com/yaook/k8s/-/merge_requests/1837>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.12.1 to 4.12.2 (`!1843 <https://gitlab.com/yaook/k8s/-/merge_requests/1843>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 16.0.4 to 16.0.5 (`!1850 <https://gitlab.com/yaook/k8s/-/merge_requests/1850>`_)
- ``curl`` has been moved from the interactive dependency group to the default dependency group as it is required for managing the Terraform state with Gitlab as backend. (`!1851 <https://gitlab.com/yaook/k8s/-/merge_requests/1851>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 72.0.0 to 72.1.0 (`!1853 <https://gitlab.com/yaook/k8s/-/merge_requests/1853>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 16.0.5 to 16.0.6 (`!1854 <https://gitlab.com/yaook/k8s/-/merge_requests/1854>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 72.1.0 to 72.1.1 (`!1855 <https://gitlab.com/yaook/k8s/-/merge_requests/1855>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 9.5.0 to 9.6.0 (`!1857 <https://gitlab.com/yaook/k8s/-/merge_requests/1857>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator from 0.20250429.0 to 0.20250507.0 (`!1858 <https://gitlab.com/yaook/k8s/-/merge_requests/1858>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 72.1.1 to 72.3.0 (`!1859 <https://gitlab.com/yaook/k8s/-/merge_requests/1859>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.1.0 to 4.1.1 (`!1863 <https://gitlab.com/yaook/k8s/-/merge_requests/1863>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 16.0.6 to 16.0.7 (`!1864 <https://gitlab.com/yaook/k8s/-/merge_requests/1864>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 72.3.0 to 72.5.2 (`!1867 <https://gitlab.com/yaook/k8s/-/merge_requests/1867>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 72.5.2 to 72.6.2 (`!1869 <https://gitlab.com/yaook/k8s/-/merge_requests/1869>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 72.6.2 to 72.9.1 (`!1873 <https://gitlab.com/yaook/k8s/-/merge_requests/1873>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 9.6.0 to 9.8.0 (`!1874 <https://gitlab.com/yaook/k8s/-/merge_requests/1874>`_)
- The ``nixpkgs.url`` has been changed to 25.05. (`!1880 <https://gitlab.com/yaook/k8s/-/merge_requests/1880>`_)
- The default for :ref:`configuration-options.yk8s.kubernetes.version` has been bumped to v1.32.

  .. note::

     It is important, that a cluster's configuration reflects the deployed Kubernetes version.

     Take a look at the following document for upgrade instructions:
     :doc:`/user/guide/kubernetes/upgrading-kubernetes`. (`!1880 <https://gitlab.com/yaook/k8s/-/merge_requests/1880>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.1.1 to 4.1.3 (`!1883 <https://gitlab.com/yaook/k8s/-/merge_requests/1883>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.12.2 to 4.12.3 (`!1884 <https://gitlab.com/yaook/k8s/-/merge_requests/1884>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator from 0.20250507.0 to 0.20250605.2 (`!1885 <https://gitlab.com/yaook/k8s/-/merge_requests/1885>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 73.1.0 to 73.2.0 (`!1886 <https://gitlab.com/yaook/k8s/-/merge_requests/1886>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.17.2 to v1.18.0 (`!1891 <https://gitlab.com/yaook/k8s/-/merge_requests/1891>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator from 0.20250605.2 to 0.20250612.0 (`!1893 <https://gitlab.com/yaook/k8s/-/merge_requests/1893>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 73.2.0 to 73.2.3 (`!1900 <https://gitlab.com/yaook/k8s/-/merge_requests/1900>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.18.0 to v1.18.1 (`!1904 <https://gitlab.com/yaook/k8s/-/merge_requests/1904>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator from 0.20250612.0 to 0.20250626.2 (`!1906 <https://gitlab.com/yaook/k8s/-/merge_requests/1906>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.18.1 to v1.18.2 (`!1911 <https://gitlab.com/yaook/k8s/-/merge_requests/1911>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator from 0.20250626.2 to 0.20250703.1 (`!1913 <https://gitlab.com/yaook/k8s/-/merge_requests/1913>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.12.3 to 4.13.0 (`!1917 <https://gitlab.com/yaook/k8s/-/merge_requests/1917>`_)
- The default Kubernetes version in the configuration template has been bumped to ``1.32.5``. (`!1924 <https://gitlab.com/yaook/k8s/-/merge_requests/1924>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.1.3 to 4.2.0 (`!1929 <https://gitlab.com/yaook/k8s/-/merge_requests/1929>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator/stable/ from 0.20250703.1 to 0.20250710.0 (`!1930 <https://gitlab.com/yaook/k8s/-/merge_requests/1930>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.0.0 to 11.0.1 (`!1933 <https://gitlab.com/yaook/k8s/-/merge_requests/1933>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 17.2.0 to 17.2.1 (`!1939 <https://gitlab.com/yaook/k8s/-/merge_requests/1939>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.0.1 to 11.1.0 (`!1941 <https://gitlab.com/yaook/k8s/-/merge_requests/1941>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator from 0.20250710.0 to 0.20250717.0 (`!1942 <https://gitlab.com/yaook/k8s/-/merge_requests/1942>`_)
- Updated default version of helm chart prometheus-adapter of https://github.com/prometheus-community/helm-charts from 4.14.1 to 4.14.2 (`!1946 <https://gitlab.com/yaook/k8s/-/merge_requests/1946>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.1.0 to 11.1.1 (`!1947 <https://gitlab.com/yaook/k8s/-/merge_requests/1947>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 17.2.1 to 17.2.2 (`!1951 <https://gitlab.com/yaook/k8s/-/merge_requests/1951>`_)
- Updated default version of helm chart thanos of https://github.com/bitnami/charts from 17.2.2 to 17.2.3 (`!1954 <https://gitlab.com/yaook/k8s/-/merge_requests/1954>`_)
- Updated default version of helm chart etcdbackup of https://charts.yaook.cloud/operator from 0.20250717.0 to 0.20250724.0 (`!1955 <https://gitlab.com/yaook/k8s/-/merge_requests/1955>`_)


Bugfixes
~~~~~~~~

- Helm invocations have been decoupled from the local Helm state. (`!644 <https://gitlab.com/yaook/k8s/-/merge_requests/644>`_, `!1894 <https://gitlab.com/yaook/k8s/-/merge_requests/1894>`_)
- The version selection dropup in the documentation's sidebar
  is now properly positioned above the search bar
  and entries do not expand off-screen anymore. (`!1776 <https://gitlab.com/yaook/k8s/-/merge_requests/1776>`_)
- We fixed a bug where the :ref:`configuration-options.yk8s.k8s-service-layer.rook.scheduling_key` wasn't properly used for nodeAffinity. (`!1796 <https://gitlab.com/yaook/k8s/-/merge_requests/1796>`_)
- The ``priorityClassName`` ``system-node-critical`` is now applied to the csi-cinder-plugin again to prevent its Pods from getting evicted. (`!1824 <https://gitlab.com/yaook/k8s/-/merge_requests/1824>`_)
- The mutual exclusiveness of the config options
  :ref:`configuration-options.yk8s.kubernetes.is_gpu_cluster`
  and :ref:`configuration-options.yk8s.kubernetes.virtualize_gpu`
  is now enforced. (`!1887 <https://gitlab.com/yaook/k8s/-/merge_requests/1887>`_)
- A bug in :ref:`wg-up.sh <actions-references.wg-upsh>` has been fixed that caused ``wg_private_key_command`` to fail if it contained environment variables.
  See :ref:`environmental-variables.vpn-configuration` for an example on how to use it with `pass <https://www.passwordstore.org/>`_. (`!1899 <https://gitlab.com/yaook/k8s/-/merge_requests/1899>`_)
- The ``nopreempt`` setting of keepalived for the VRRP instances has been fixed by setting the initial states to ``BACKUP``. (`!1916 <https://gitlab.com/yaook/k8s/-/merge_requests/1916>`_)
- OpenStack security groups to allow VRRP traffic have been added. (`!1916 <https://gitlab.com/yaook/k8s/-/merge_requests/1916>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- A note has been added which clearifies that a ready-to-use container runtime
  is needed if one wants to make use of the
  :ref:`development Vault setup <initialization.initialize-vault-for-a-development-setup>`. (`!1777 <https://gitlab.com/yaook/k8s/-/merge_requests/1777>`_)
- The documentation about expected minimal changes to the environment has been improved. (`!1777 <https://gitlab.com/yaook/k8s/-/merge_requests/1777>`_)
- Releases in the sidebar are now sorted such that the recent versions appear on top. (`!1778 <https://gitlab.com/yaook/k8s/-/merge_requests/1778>`_)
- A part of documentation that is specific to the config options in :ref:`configuration-options.yk8s.terraform`
  has been moved back from :ref:`configuration-options.yk8s.openstack`.
  The documentation of both config sections received minor corrections. (`!1795 <https://gitlab.com/yaook/k8s/-/merge_requests/1795>`_)
- Any config option in the documentation is now mentioned
  with its fully qualified name in Nix dot notation.
  Additionally, those mentions link directly
  to the description of the particular config option.

  A few previously renamed or replaced config options were fixed as well. (`!1801 <https://gitlab.com/yaook/k8s/-/merge_requests/1801>`_)
- All mentions of the legacy TOML based configuration were removed
  as it has been replaced with Nix since release v9.0.0. (`!1801 <https://gitlab.com/yaook/k8s/-/merge_requests/1801>`_)
- `!1905 <https://gitlab.com/yaook/k8s/-/merge_requests/1905>`_, `!1907 <https://gitlab.com/yaook/k8s/-/merge_requests/1907>`_, `!1920 <https://gitlab.com/yaook/k8s/-/merge_requests/1920>`_
- Corrected the docs for :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup`, which previously stated to use ``endpoint_cacrt``, but now correctly states to use ``certRef``. (`!1918 <https://gitlab.com/yaook/k8s/-/merge_requests/1918>`_)
- The guide on how to :doc:`rotate OpenStack credentials </user/guide/rotate-openstack-credentials>` has been updated. (`!1928 <https://gitlab.com/yaook/k8s/-/merge_requests/1928>`_)
- The root of our documentation now redirects to ``./devel`` using HTTP redirect
  instead of HTML meta refresh. (`!1940 <https://gitlab.com/yaook/k8s/-/merge_requests/1940>`_)
- The description of :ref:`actions-references.migrate-to-releasesh` has been updated. (`!1958 <https://gitlab.com/yaook/k8s/-/merge_requests/1958>`_, `!1960 <https://gitlab.com/yaook/k8s/-/merge_requests/1960>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- The ``yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_path``
  config option is removed.
  Please use :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_objectstorage_config_file`
  instead. (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- The :ref:`configuration-options.yk8s.node-scheduling.scheduling_key_prefix` config option
  is deprecated.
  Please substitute it with a let expression (see example below).

  .. code:: diff

     - config.yk8s.node-scheduling = {
     -   scheduling_key_prefix = "foo.example.com";
     -   labels = {
     -     node-a = ["${config.yk8s.node-scheduling.scheduling_key_prefix}/label=value"];
     -   };
     - };
     + config.yk8s.node-scheduling = let
     +   scheduling_key_prefix = "foo.example.com";
     + in {
     +   labels = {
     +     node-a = ["${scheduling_key_prefix}/label=value"];
     +   };
     + };

  _ (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)
- Support for Kubernetes v1.29 has been dropped. (`!1890 <https://gitlab.com/yaook/k8s/-/merge_requests/1890>`_)
- The feature to manage IPSec tunnels (:ref:`configuration-options.yk8s.ipsec`) is deprecated and support for it will be dropped in a release after v11.0.0. (`!1950 <https://gitlab.com/yaook/k8s/-/merge_requests/1950>`_)


Other Tasks
~~~~~~~~~~~

- `!1497 <https://gitlab.com/yaook/k8s/-/merge_requests/1497>`_, `!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_, `!1745 <https://gitlab.com/yaook/k8s/-/merge_requests/1745>`_, `!1749 <https://gitlab.com/yaook/k8s/-/merge_requests/1749>`_, `!1751 <https://gitlab.com/yaook/k8s/-/merge_requests/1751>`_, `!1757 <https://gitlab.com/yaook/k8s/-/merge_requests/1757>`_, `!1774 <https://gitlab.com/yaook/k8s/-/merge_requests/1774>`_, `!1779 <https://gitlab.com/yaook/k8s/-/merge_requests/1779>`_, `!1788 <https://gitlab.com/yaook/k8s/-/merge_requests/1788>`_, `!1793 <https://gitlab.com/yaook/k8s/-/merge_requests/1793>`_, `!1802 <https://gitlab.com/yaook/k8s/-/merge_requests/1802>`_, `!1817 <https://gitlab.com/yaook/k8s/-/merge_requests/1817>`_, `!1820 <https://gitlab.com/yaook/k8s/-/merge_requests/1820>`_, `!1828 <https://gitlab.com/yaook/k8s/-/merge_requests/1828>`_, `!1832 <https://gitlab.com/yaook/k8s/-/merge_requests/1832>`_, `!1838 <https://gitlab.com/yaook/k8s/-/merge_requests/1838>`_, `!1844 <https://gitlab.com/yaook/k8s/-/merge_requests/1844>`_, `!1847 <https://gitlab.com/yaook/k8s/-/merge_requests/1847>`_, `!1860 <https://gitlab.com/yaook/k8s/-/merge_requests/1860>`_, `!1865 <https://gitlab.com/yaook/k8s/-/merge_requests/1865>`_, `!1866 <https://gitlab.com/yaook/k8s/-/merge_requests/1866>`_, `!1872 <https://gitlab.com/yaook/k8s/-/merge_requests/1872>`_, `!1876 <https://gitlab.com/yaook/k8s/-/merge_requests/1876>`_, `!1877 <https://gitlab.com/yaook/k8s/-/merge_requests/1877>`_, `!1878 <https://gitlab.com/yaook/k8s/-/merge_requests/1878>`_, `!1892 <https://gitlab.com/yaook/k8s/-/merge_requests/1892>`_, `!1897 <https://gitlab.com/yaook/k8s/-/merge_requests/1897>`_, `!1901 <https://gitlab.com/yaook/k8s/-/merge_requests/1901>`_, `!1916 <https://gitlab.com/yaook/k8s/-/merge_requests/1916>`_, `!1919 <https://gitlab.com/yaook/k8s/-/merge_requests/1919>`_, `!1922 <https://gitlab.com/yaook/k8s/-/merge_requests/1922>`_, `!1923 <https://gitlab.com/yaook/k8s/-/merge_requests/1923>`_, `!1925 <https://gitlab.com/yaook/k8s/-/merge_requests/1925>`_, `!1926 <https://gitlab.com/yaook/k8s/-/merge_requests/1926>`_, `!1932 <https://gitlab.com/yaook/k8s/-/merge_requests/1932>`_, `!1948 <https://gitlab.com/yaook/k8s/-/merge_requests/1948>`_, `!1952 <https://gitlab.com/yaook/k8s/-/merge_requests/1952>`_, `!1961 <https://gitlab.com/yaook/k8s/-/merge_requests/1961>`_
- A fixture for unit testing nix code has been added
  along with the `unit-tests` CI stage and `test-nix-yk8s` CI job
  for running these unit tests. (`!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_)


Misc
~~~~

- `!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_, `!1731 <https://gitlab.com/yaook/k8s/-/merge_requests/1731>`_, `!1736 <https://gitlab.com/yaook/k8s/-/merge_requests/1736>`_, `!1744 <https://gitlab.com/yaook/k8s/-/merge_requests/1744>`_, `!1782 <https://gitlab.com/yaook/k8s/-/merge_requests/1782>`_, `!1792 <https://gitlab.com/yaook/k8s/-/merge_requests/1792>`_, `!1809 <https://gitlab.com/yaook/k8s/-/merge_requests/1809>`_, `!1812 <https://gitlab.com/yaook/k8s/-/merge_requests/1812>`_, `!1815 <https://gitlab.com/yaook/k8s/-/merge_requests/1815>`_, `!1818 <https://gitlab.com/yaook/k8s/-/merge_requests/1818>`_, `!1829 <https://gitlab.com/yaook/k8s/-/merge_requests/1829>`_, `!1830 <https://gitlab.com/yaook/k8s/-/merge_requests/1830>`_, `!1842 <https://gitlab.com/yaook/k8s/-/merge_requests/1842>`_, `!1845 <https://gitlab.com/yaook/k8s/-/merge_requests/1845>`_, `!1871 <https://gitlab.com/yaook/k8s/-/merge_requests/1871>`_, `!1889 <https://gitlab.com/yaook/k8s/-/merge_requests/1889>`_
