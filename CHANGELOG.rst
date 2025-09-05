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

v9.0.14 (2025-09-05)
--------------------

Bugfixes
~~~~~~~~

- A bug in the migration script resulting in infinite recursion has been fixed (`!2093 <https://gitlab.com/yaook/k8s/-/merge_requests/2093>`_)
- k8s-login run in :doc:`root CA rotation </user/guide/vault/vault-ca-rotation>` phase 1
  works again with a Vault token only having the ``yaook/orchestrator`` policy.
  (regression of v9.0.11)

  .. note:: Action needed

     To activate the fix the Vault orchestrator policy needs to be updated.

     .. code:: shell

        VAULT_TOKEN=$vault_root_token ./managed-k8s/tools/vault/init.sh

  _ (`!2093 <https://gitlab.com/yaook/k8s/-/merge_requests/2093>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Changelogs of previous releases have been dropped.
  These are still accessible when switching to the respective version.
  From now on, changelogs for each version will be maintained separately and not continously. (`!2093 <https://gitlab.com/yaook/k8s/-/merge_requests/2093>`_)


Misc
~~~~

- `!2093 <https://gitlab.com/yaook/k8s/-/merge_requests/2093>`_


v9.0.13 (2025-08-19)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The Thanos image repository has been set to ``bitnamilegacy/thanos`` due to `recent changes by the Bitnami offering <https://github.com/bitnami/containers/issues/83267>`_. (`!1990 <https://gitlab.com/yaook/k8s/-/merge_requests/1990>`_)


v9.0.12 (2025-08-13)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The project has been renamed from YAOOK/K8s to TAROOK.
  The repository location has been updated to reflect this change. (`!2001 <https://gitlab.com/yaook/k8s/-/merge_requests/2001>`_)


Other Tasks
~~~~~~~~~~~

- `!2001 <https://gitlab.com/yaook/k8s/-/merge_requests/2001>`_


v9.0.11 (2025-07-16)
--------------------

Bugfixes
~~~~~~~~~~~~

- The CA rotation procedure has been fixed once again
  including force-renewal of the certificates and kubeconfig on Kubernetes nodes
  and k8s-login for the orchestrator's kubeconfig. (`!1935 <https://gitlab.com/yaook/k8s/-/merge_requests/1935>`_)


v9.0.10 (2025-05-07)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- We are now using packages from NixOS stable.
  One reason for that is that we're using boto3 to manage the S3 bucket
  for :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup`,
  but the latest versions of boto3 are `incompatible to OpenStack Swift <https://github.com/boto/botocore/issues/3415>`_. (`!1848 <https://gitlab.com/yaook/k8s/-/merge_requests/1848>`_)


v9.0.9 (2025-05-05)
-------------------

Bugfixes
~~~~~~~~

- Fixed application of :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.basic_auth_secret_name` when unset. (regression of v9.0.6) (`!1839 <https://gitlab.com/yaook/k8s/-/merge_requests/1839>`_)
- Fixed application of :ref:`configuration-options.yk8s.miscellaneous.openstack_cinder_volume_type` when unset. (regression of v9.0.6) (`!1839 <https://gitlab.com/yaook/k8s/-/merge_requests/1839>`_)


v9.0.8 (2025-04-15)
-------------------

Bugfixes
~~~~~~~~

- A minor bug in the monitoring playbook got fixed
  that caused it to fail
  if no CRD update is needed. (`!1781 <https://gitlab.com/yaook/k8s/-/merge_requests/1781>`_)


v9.0.7 (2025-03-27)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed which accidentally applied the Prometheus resource requests and limits :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources` also to the operator :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources`. (`!1771 <https://gitlab.com/yaook/k8s/-/merge_requests/1771>`_)


v9.0.6 (2025-03-27)
-------------------

.. attention:: This release introduced two minor regressions

  The ``connect-k8s-to-openstack`` Ansible role fails if :ref:`configuration-options.yk8s.miscellaneous.openstack_cinder_volume_type` is unset.

  Likewise, the ``monitoring_v2`` Ansible role fails if :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.basic_auth_secret_name` is unset.

  These regressions are fixed with release v9.0.9.

Bugfixes
~~~~~~~~

- The default value of option :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.common_labels` has been set to an empty set again such that Prometheus collects all ServiceMonitors by default. (`!1768 <https://gitlab.com/yaook/k8s/-/merge_requests/1768>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- The option :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.basic_auth_secret_name` has been added to documentation. (`!1768 <https://gitlab.com/yaook/k8s/-/merge_requests/1768>`_)


v9.0.5 (2025-03-25)
-------------------

Bugfixes
~~~~~~~~

- Fix IP address autodetection in Calico when used with VRRP on the hosts

  If keepalived was installed on a host, Calico would sometimes incorrectly pick
  the VRRP address as node address. While generally harmless, this could cause
  calico-node to break during/after VRRP failovers because it would then see
  the VRRP address on a different node all of a sudden, leading to a node IP
  address conflict. (`!1753 <https://gitlab.com/yaook/k8s/-/merge_requests/1753>`_)


v9.0.4 (2025-03-25)
-------------------

Bugfixes
~~~~~~~~

- Due to a vulnerability in the ingress-nginx admission controller, ingress-nginx has been updated. (`!1761 <https://gitlab.com/yaook/k8s/-/merge_requests/1761>`_)


v9.0.3 (2025-03-07)
-------------------

Bugfixes
~~~~~~~~

- The :doc:`bare metal simulation guide <developer/guide/simulate-bm>` has been fixed.
  (regression of release v9.0.0) (`!1728 <https://gitlab.com/yaook/k8s/-/merge_requests/1728>`_)


v9.0.2 (2025-03-04)
-------------------

Bugfixes
~~~~~~~~

- The type of the ``yk8s.rook.nodes.devices`` config option was fixed.
  (regression of release v9.0.0) (`!1725 <https://gitlab.com/yaook/k8s/-/merge_requests/1725>`_)


v9.0.1 (2025-02-19)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed that made the inventory updater erroneously output
  ``error: Neither IPv4 nor IPv6 are enabled.`` to users with a broken locale
  setup and swallowed any error output related to that. (`!1677 <https://gitlab.com/yaook/k8s/-/merge_requests/1677>`_)
- An envrc function has been added to address common locale issues on non-NixOS systems. (`!1679 <https://gitlab.com/yaook/k8s/-/merge_requests/1679>`_)
- A bug has been fixed that caused k8s-supplements to fail if :ref:`configuration-options.yk8s.miscellaneous.openstack_cinder_volume_type` was not set. (`!1688 <https://gitlab.com/yaook/k8s/-/merge_requests/1688>`_)
- ``pre-commit`` has been added back to the default group. (`!1693 <https://gitlab.com/yaook/k8s/-/merge_requests/1693>`_)
- The default value of :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.scheduling_key` for thanos_v2 has been fixed. (`!1693 <https://gitlab.com/yaook/k8s/-/merge_requests/1693>`_)
- A bug regarding the renaming of ``pod_limit`` to ``pod_limit_worker`` has been fixed. (`!1693 <https://gitlab.com/yaook/k8s/-/merge_requests/1693>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Instructions on how to :ref:`Install system requirements. <initialization.install-system-requirements>` have been refined.
  We additionally explain how to install on Ubuntu 24.04 from Ubuntu repositories now. (`!1689 <https://gitlab.com/yaook/k8s/-/merge_requests/1689>`_)


Other Tasks
~~~~~~~~~~~

- `!1671 <https://gitlab.com/yaook/k8s/-/merge_requests/1671>`_, `!1674 <https://gitlab.com/yaook/k8s/-/merge_requests/1674>`_, `!1681 <https://gitlab.com/yaook/k8s/-/merge_requests/1681>`_


v9.0.0 (2025-02-14)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- The configuration has been reworked and is now based on Nix, which makes Nix a hard dependency.

  All configuration options are documented at :doc:`/user/reference/options/index`.

  The cluster repository layout has changed:

  ::

     your_cluster_repo
     ├── config/                           # All user configuration now resides in this directory
     │   ├── default.nix                   # Nix-based cluster configuration
     │   └── hosts                         # Manual Ansible hosts file for bare-metal, referenced in default.nix
     ├── inventory/yaook-k8s/              # Ansible inventory is now completely generated and MAY be excluded from version control
     │   ├── group-vars/                   # Variables passed to Ansible
     │   └── hosts                         # Ansible hosts file, generated from config even for bare-metal
     ├── state/                            # Auto-generated files that need to be preserved. MUST be checked into version control
     │   ├── wireguard/
     │   │   └── ipam.toml                 # WireGuard IP address management
     │   ├── terraform/                    # Terraform specific state files
     ┊   ┊



  .. attention:: Action required

      Ensure you've installed and configured Nix according to :ref:`initialization.install-system-requirements`

  .. attention:: Action required

      In order to migrate to the new cluster repository layout, run

      .. code:: console

         $ ./managed-k8s/actions/migrate-cluster-repo.sh

      The first run may fail, because manual adjustments to the config are required.
      These cases require manual action:

      * Jinja templates in values need to be replaced with the equivalent Nix expressions
      * Options that no longer exist need to be removed
      * Custom config options you may have added must be moved to the ``custom`` section

      The migration script will point out these cases.

  _ (`!1265 <https://gitlab.com/yaook/k8s/-/merge_requests/1265>`_)
- The following Terraform resources are deprecated and have been updated:

  - ``openstack_compute_floatingip_associate_v2``
    replaced by ``openstack_networking_floatingip_associate_v2``

    .. attention:: Action required

       For the replacement to be perfomed correctly (therefore non-disruptive)
       you must run the migration script
       *before* any apply-terraform action.

       .. code::

          ./managed-k8s/actions/migrate-cluster-repo.sh

  _ (`!1562 <https://gitlab.com/yaook/k8s/-/merge_requests/1562>`_, `!1667 <https://gitlab.com/yaook/k8s/-/merge_requests/1667>`_)
- The Vault S3 backup configuration file moved to Vault.

  .. attention:: You must update the Vault policies.

  .. note:: A root token must be sourced.

  .. code:: console

     $ bash managed-k8s/tools/vault/init.sh

  If :ref:`configuration-options.yk8s.k8s-service-layer.vault.enabled` is true
  and :ref:`configuration-options.yk8s.k8s-service-layer.vault.enable_backups`
  is true, you addditionally have to import the S3 backup config to Vault.

  Inserting the Vault S3 backup config into Vault can be automated by
  storing the configuration at ``config/vault_backup_s3_config.yaml``.
  Please check the documentation on :doc:`/user/reference/services/vault`
  how to create a configuration.

  .. note:: A root token must be sourced.

  .. code:: console

     $ bash managed-k8s/tools/vault/update.sh
     $ bash managed-k8s/actions/apply-k8s-supplements.sh install-vault.yaml

  _ (`!1616 <https://gitlab.com/yaook/k8s/-/merge_requests/1616>`_)
- The ``.gitignore``-template has been changed and
  starting with this release,
  it is highly recommended that ``inventory/`` is ignored
  and not checked into version control.

  .. attention:: Action required

      You must run the migration script to ensure your
      ``.gitignore`` contains the necessary entries
      and ``inventory/`` is removed from version control:

      .. code::

        ./managed-k8s/actions/migrate-cluster-repo.sh

  _ (`!1653 <https://gitlab.com/yaook/k8s/-/merge_requests/1653>`_)


New Features
~~~~~~~~~~~~

- Automatic evaluation of the devShell can now be disabled by setting ``YAOOK_K8S_DIRENV_MANUAL=true`` in ``.config/yaook-k8s/env`` or ``.envrc.local`` (`!1323 <https://gitlab.com/yaook/k8s/-/merge_requests/1323>`_)
- The default version of rook has been bumped to v1.15.4. (`!1453 <https://gitlab.com/yaook/k8s/-/merge_requests/1453>`_)
- Add multicluster support for grafana dashoards (`!1483 <https://gitlab.com/yaook/k8s/-/merge_requests/1483>`_)
- Add support for basic auth in Prometheus remote write (`!1484 <https://gitlab.com/yaook/k8s/-/merge_requests/1484>`_)
- The LCM continuously ensures that
  all Kubernetes control plane and worker nodes are labeled with
  ``node-role.kubernetes.io/control-plane=``
  xor ``node-role.kubernetes.io/worker=``
  respectively.

  This is part of the concept of LCM managed labels
  which is introduced at the same time.
  Refer to the :ref:`documentation <cluster.node-labeling>` for details.

  Amongst other things,
  this allows monitoring and alerting solutions
  to reliably target nodes by their role.
  For instance,
  the :doc:`monitoring stack </user/guide/monitoring/prometheus-stack>`
  that can optionally be installed with YAOOK/k8s,
  exposes the |kube_node_role|_ metric.

  .. |kube_node_role| replace:: ``kube_node_role``
  .. _kube_node_role: https://github.com/kubernetes/kube-state-metrics/blob/main/docs/metrics/cluster/node-metrics.md

  _ (`!1587 <https://gitlab.com/yaook/k8s/-/merge_requests/1587>`_)
- Kubernetes node labels and taints are now applied on LCM rollout instead on node join.
  This allows additions and changes of node labels and taints through the
  :ref:`config <configuration-options.yk8s.node-scheduling.labels>`
  **after the respective node joined the cluster**.
  Removal is still unsupported.

  related documentation: :doc:`Scheduling (Taints and Labels) </user/explanation/node-scheduling>` (`!1597 <https://gitlab.com/yaook/k8s/-/merge_requests/1597>`_)
- A script has been added which can be used to create new CSRs for clusters using intermediate CAs.
  A procedure description has been added to the documentation: :ref:`vault.importing-new-intermediates`. (`!1599 <https://gitlab.com/yaook/k8s/-/merge_requests/1599>`_)
- Add support for specifying the maximum number of pods allowed to be scheduled on master nodes (maxPods).
  The former configuration option ``pod_limit`` only allowed modifying maxPods for worker nodes.
  We now support setting maxPods for both master nodes and worker nodes introducing two different configuration options
  :ref:`configuration-options.yk8s.kubernetes.kubelet.pod_limit_master`
  and
  :ref:`configuration-options.yk8s.kubernetes.kubelet.pod_limit_worker` (`!1606 <https://gitlab.com/yaook/k8s/-/merge_requests/1606>`_)
- A new option has been added which allows to configure a specific volume type for the ``csi-sc-cinderplugin`` StorageClass: :ref:`configuration-options.yk8s.miscellaneous.openstack_cinder_volume_type`. (`!1617 <https://gitlab.com/yaook/k8s/-/merge_requests/1617>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The Prometheus integration with Vault has been updated to use a long-lived periodic token.

  To activate this change, the Vault policy must be updated.

  Follow these steps:

  - Retrieve the root token from the Vault instance running within Kubernetes.
  - Write the root token to the file ``etc/vault_root_token`` in the cluster repository.
  - Execute the following command to complete the process:

  .. code::

      ./managed-k8s/actions/apply-k8s-supplements.sh install-vault.yaml

  _ (`!1456 <https://gitlab.com/yaook/k8s/-/merge_requests/1456>`_)
- Most options from the terraform configuration section have moved into one of two new sections, either ``openstack`` for OpenStack specific options or ``infra`` for options used by all clusters. Have a look at the deprecation warnings during Nix evaluation. (`!1466 <https://gitlab.com/yaook/k8s/-/merge_requests/1466>`_)
- ``vault.cluster_name`` now defaults to ``infra.cluster_name`` (`!1466 <https://gitlab.com/yaook/k8s/-/merge_requests/1466>`_)
- Cloud&Heat specific default have been removed from the Terraform module. (`!1504 <https://gitlab.com/yaook/k8s/-/merge_requests/1504>`_)
- Depending on the IP version enabled, node address autodetection is explicitly set to ``{}``. (`!1529 <https://gitlab.com/yaook/k8s/-/merge_requests/1529>`_)
- Additional testing in the CI pipeline has been added that verifies that :doc:`Kubernetes certificate signing </user/guide/kubernetes/restore-certificate-signing-ability>` is functional. (`!1543 <https://gitlab.com/yaook/k8s/-/merge_requests/1543>`_)
- The default blackbox-exporter version has been bumped to v9.1.0. (`!1575 <https://gitlab.com/yaook/k8s/-/merge_requests/1575>`_)
- The default version of the Prometheus stack has been bumped to v66.2.2. (`!1575 <https://gitlab.com/yaook/k8s/-/merge_requests/1575>`_)
- The default version of Prometheus adapter has been bumped to v4.11.0. (`!1575 <https://gitlab.com/yaook/k8s/-/merge_requests/1575>`_)
- The default Thanos version has been bumped to v15.8.2. (`!1575 <https://gitlab.com/yaook/k8s/-/merge_requests/1575>`_)
- The Kubernetes upgrade procedure has been adjusted such that the system update happens after switching to the next Kubernetes repository. (`!1586 <https://gitlab.com/yaook/k8s/-/merge_requests/1586>`_)
- The Prometheus node exporter metrics now additionally contain a ``role`` label which reflects the Kubernetes role of the node.
  Based upon if a node is labeled with ``node-role.kubernetes.io/worker`` or ``node-role.kubernetes.io/control-plane``,
  the value is either ``worker`` or ``control-plane``. (`!1596 <https://gitlab.com/yaook/k8s/-/merge_requests/1596>`_)
- The Nix binary cache has been moved to a new location. Please remove all occurences of "tarook.cachix.org" and, if desired, configure

    .. code:: ini

       extra-substituters = https://nix-cache.tarook.cloud
       extra-trusted-public-keys = nix-cache.tarook.cloud-2:2X2yPTrpwmakhSgS83FVB2fKkG6IzfOJ1AGIIcvNyM0=

  in ``/etc/nix/nix.conf``. Then do ``systemctl restart nix-daemon.service`` for the change to take effect immediately. (`!1600 <https://gitlab.com/yaook/k8s/-/merge_requests/1600>`_)
- The default Kubernetes version and the internally used ones have been bumped to their latest patch releases. (`!1607 <https://gitlab.com/yaook/k8s/-/merge_requests/1607>`_)


Bugfixes
~~~~~~~~

- Marked the following immutable config setting as such:

  * ``k8s-service-layer.prometheus.thanos_storegateway_size``
  * ``k8s-service-layer.prometheus.thanos_storegateway_size``
  * ``k8s-service-layer.prometheus.thanos_compactor_size``
  * ``k8s-service-layer.rook.mon_volume_storage_class``
  * ``k8s-service-layer.rook.mon_volume_size``
  * ``k8s-service-layer.rook.osd_volume_size``
  * ``k8s-service-layer.rook.osd_storage_class``

  A manual workaround to change these settings nonetheless
  is outlined in the respective documentation. (`!1498 <https://gitlab.com/yaook/k8s/-/merge_requests/1498>`_)
- Fixed Ansible to never assume any host in the ``gateways`` host group. (`!1503 <https://gitlab.com/yaook/k8s/-/merge_requests/1503>`_)
- The proxy-support role has been fixed.
  A missing template has been re-added. (`!1528 <https://gitlab.com/yaook/k8s/-/merge_requests/1528>`_)
- The type of ``k8s-service-layer.prometheus.remote_writes`` has been fixed. (`!1541 <https://gitlab.com/yaook/k8s/-/merge_requests/1541>`_)
- The regex for the option type that handles memory and volume sizes has been fixed to allow fractional values. (`!1544 <https://gitlab.com/yaook/k8s/-/merge_requests/1544>`_)
- Thanos compactor is now restarted on failure.
  Previously it just stopped operation but never exited
  (see `issue #724 <https://gitlab.com/yaook/k8s/-/issues/724>`_). (`!1592 <https://gitlab.com/yaook/k8s/-/merge_requests/1592>`_)
- The YAOOK/K8s Terraform module does not fail anymore
  if there are multiple Openstack images with the same name
  but simply selects the most recent one. (`!1598 <https://gitlab.com/yaook/k8s/-/merge_requests/1598>`_)
- A bug has been fixed which caused Kubernetes upgrades to fail if :ref:`configuration-options.yk8s.kubernetes.controller_manager.enable_signing_requests` is enabled. (`!1608 <https://gitlab.com/yaook/k8s/-/merge_requests/1608>`_, `!1675 <https://gitlab.com/yaook/k8s/-/merge_requests/1675>`_)
- A bug has been fixed that made the ``nix-fmt`` pre-commit check always fail. (`!1614 <https://gitlab.com/yaook/k8s/-/merge_requests/1614>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- direnv has been marked as requirement (`!1512 <https://gitlab.com/yaook/k8s/-/merge_requests/1512>`_)
- A ``jq`` command was fixed in
  :doc:`the Openstack credentials rotation guide </user/guide/rotate-openstack-credentials>`. (`!1555 <https://gitlab.com/yaook/k8s/-/merge_requests/1555>`_)
- Unused variables were removed, and Vault documentation has been updated
  to eliminate outdated path references. (`!1557 <https://gitlab.com/yaook/k8s/-/merge_requests/1557>`_)
- The exact format of the ``wg_conf_name`` environment variable
  is mentioned in the :ref:`documentation <environmental-variables.vpn-configuration>`. (`!1579 <https://gitlab.com/yaook/k8s/-/merge_requests/1579>`_)
- A short description about ``tools/vault/rotate-root-ca-intermediate.sh`` and ``tools/vault/rotate-root-ca-root.sh`` has been added. (`!1599 <https://gitlab.com/yaook/k8s/-/merge_requests/1599>`_)
- A short description about ``tools/vault/update.sh`` has been added. (`!1599 <https://gitlab.com/yaook/k8s/-/merge_requests/1599>`_)
- A user facing :doc:`tutorial <user/tutorial/upgrade-release>` has been created,
  which describes how to upgrade to a new YAOOK/K8s release. (`!1602 <https://gitlab.com/yaook/k8s/-/merge_requests/1602>`_, `!1660 <https://gitlab.com/yaook/k8s/-/merge_requests/1660>`_)
- The Terraform developer reference documentation has been dropped in favor of :ref:`configuration-options.yk8s.terraform`. (`!1611 <https://gitlab.com/yaook/k8s/-/merge_requests/1611>`_)
- Some typos have been fixed (`!1615 <https://gitlab.com/yaook/k8s/-/merge_requests/1615>`_)
- Minor fixes in the docs. (`!1642 <https://gitlab.com/yaook/k8s/-/merge_requests/1642>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- YAOOK/K8s switched from Poetry to Nix for managing Python dependencies. Please remove all occurences of ``layout poetry`` in your ``.envrc`` (`!1570 <https://gitlab.com/yaook/k8s/-/merge_requests/1570>`_)
- Support for Kubernetes v1.28 has been dropped and along with it the deprecated manifest-based way to deploy the CCM and the cinder CSI plugin. (`!1622 <https://gitlab.com/yaook/k8s/-/merge_requests/1622>`_)


Other Tasks
~~~~~~~~~~~

- `!1280 <https://gitlab.com/yaook/k8s/-/merge_requests/1280>`_, `!1493 <https://gitlab.com/yaook/k8s/-/merge_requests/1493>`_, `!1502 <https://gitlab.com/yaook/k8s/-/merge_requests/1502>`_, `!1505 <https://gitlab.com/yaook/k8s/-/merge_requests/1505>`_, `!1508 <https://gitlab.com/yaook/k8s/-/merge_requests/1508>`_, `!1509 <https://gitlab.com/yaook/k8s/-/merge_requests/1509>`_, `!1514 <https://gitlab.com/yaook/k8s/-/merge_requests/1514>`_, `!1515 <https://gitlab.com/yaook/k8s/-/merge_requests/1515>`_, `!1516 <https://gitlab.com/yaook/k8s/-/merge_requests/1516>`_, `!1517 <https://gitlab.com/yaook/k8s/-/merge_requests/1517>`_, `!1518 <https://gitlab.com/yaook/k8s/-/merge_requests/1518>`_, `!1519 <https://gitlab.com/yaook/k8s/-/merge_requests/1519>`_, `!1520 <https://gitlab.com/yaook/k8s/-/merge_requests/1520>`_, `!1526 <https://gitlab.com/yaook/k8s/-/merge_requests/1526>`_, `!1527 <https://gitlab.com/yaook/k8s/-/merge_requests/1527>`_, `!1537 <https://gitlab.com/yaook/k8s/-/merge_requests/1537>`_, `!1538 <https://gitlab.com/yaook/k8s/-/merge_requests/1538>`_, `!1554 <https://gitlab.com/yaook/k8s/-/merge_requests/1554>`_, `!1561 <https://gitlab.com/yaook/k8s/-/merge_requests/1561>`_, `!1571 <https://gitlab.com/yaook/k8s/-/merge_requests/1571>`_, `!1572 <https://gitlab.com/yaook/k8s/-/merge_requests/1572>`_, `!1573 <https://gitlab.com/yaook/k8s/-/merge_requests/1573>`_, `!1574 <https://gitlab.com/yaook/k8s/-/merge_requests/1574>`_, `!1577 <https://gitlab.com/yaook/k8s/-/merge_requests/1577>`_, `!1588 <https://gitlab.com/yaook/k8s/-/merge_requests/1588>`_, `!1589 <https://gitlab.com/yaook/k8s/-/merge_requests/1589>`_, `!1591 <https://gitlab.com/yaook/k8s/-/merge_requests/1591>`_, `!1618 <https://gitlab.com/yaook/k8s/-/merge_requests/1618>`_, `!1619 <https://gitlab.com/yaook/k8s/-/merge_requests/1619>`_, `!1621 <https://gitlab.com/yaook/k8s/-/merge_requests/1621>`_, `!1628 <https://gitlab.com/yaook/k8s/-/merge_requests/1628>`_, `!1633 <https://gitlab.com/yaook/k8s/-/merge_requests/1633>`_, `!1634 <https://gitlab.com/yaook/k8s/-/merge_requests/1634>`_, `!1651 <https://gitlab.com/yaook/k8s/-/merge_requests/1651>`_, `!1666 <https://gitlab.com/yaook/k8s/-/merge_requests/1666>`_, `!1668 <https://gitlab.com/yaook/k8s/-/merge_requests/1668>`_, `!1670 <https://gitlab.com/yaook/k8s/-/merge_requests/1670>`_, `!1678 <https://gitlab.com/yaook/k8s/-/merge_requests/1678>`_
- Ubuntu 24.04 is now the default image for Kubernetes nodes and tested in the CI. (`!1610 <https://gitlab.com/yaook/k8s/-/merge_requests/1610>`_)


Misc
~~~~

- `!1278 <https://gitlab.com/yaook/k8s/-/merge_requests/1278>`_, `!1489 <https://gitlab.com/yaook/k8s/-/merge_requests/1489>`_, `!1550 <https://gitlab.com/yaook/k8s/-/merge_requests/1550>`_, `!1556 <https://gitlab.com/yaook/k8s/-/merge_requests/1556>`_, `!1567 <https://gitlab.com/yaook/k8s/-/merge_requests/1567>`_, `!1586 <https://gitlab.com/yaook/k8s/-/merge_requests/1586>`_, `!1586 <https://gitlab.com/yaook/k8s/-/merge_requests/1586>`_, `!1593 <https://gitlab.com/yaook/k8s/-/merge_requests/1593>`_, `!1595 <https://gitlab.com/yaook/k8s/-/merge_requests/1595>`_, `!1597 <https://gitlab.com/yaook/k8s/-/merge_requests/1597>`_, `!1603 <https://gitlab.com/yaook/k8s/-/merge_requests/1603>`_, `!1604 <https://gitlab.com/yaook/k8s/-/merge_requests/1604>`_, `!1607 <https://gitlab.com/yaook/k8s/-/merge_requests/1607>`_, `!1612 <https://gitlab.com/yaook/k8s/-/merge_requests/1612>`_, `!1617 <https://gitlab.com/yaook/k8s/-/merge_requests/1617>`_, `!1620 <https://gitlab.com/yaook/k8s/-/merge_requests/1620>`_, `!1627 <https://gitlab.com/yaook/k8s/-/merge_requests/1627>`_, `!1629 <https://gitlab.com/yaook/k8s/-/merge_requests/1629>`_, `!1632 <https://gitlab.com/yaook/k8s/-/merge_requests/1632>`_, `!1635 <https://gitlab.com/yaook/k8s/-/merge_requests/1635>`_, `!1636 <https://gitlab.com/yaook/k8s/-/merge_requests/1636>`_, `!1637 <https://gitlab.com/yaook/k8s/-/merge_requests/1637>`_, `!1638 <https://gitlab.com/yaook/k8s/-/merge_requests/1638>`_, `!1639 <https://gitlab.com/yaook/k8s/-/merge_requests/1639>`_, `!1641 <https://gitlab.com/yaook/k8s/-/merge_requests/1641>`_, `!1643 <https://gitlab.com/yaook/k8s/-/merge_requests/1643>`_, `!1644 <https://gitlab.com/yaook/k8s/-/merge_requests/1644>`_, `!1645 <https://gitlab.com/yaook/k8s/-/merge_requests/1645>`_, `!1646 <https://gitlab.com/yaook/k8s/-/merge_requests/1646>`_, `!1648 <https://gitlab.com/yaook/k8s/-/merge_requests/1648>`_, `!1650 <https://gitlab.com/yaook/k8s/-/merge_requests/1650>`_, `!1664 <https://gitlab.com/yaook/k8s/-/merge_requests/1664>`_, `!1669 <https://gitlab.com/yaook/k8s/-/merge_requests/1669>`_
