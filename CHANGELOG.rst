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

v9.1.16 (2025-09-05)
--------------------

Bugfixes
~~~~~~~~

- k8s-login run in :doc:`root CA rotation </user/guide/vault/vault-ca-rotation>` phase 1
  works again with a Vault token only having the ``yaook/orchestrator`` policy.
  (regression of v9.1.10)

  .. note:: Action needed

     To activate the fix the Vault orchestrator policy needs to be updated.

     .. code:: shell

        VAULT_TOKEN=$vault_root_token ./managed-k8s/tools/vault/init.sh

  _ (`!2094 <https://gitlab.com/yaook/k8s/-/merge_requests/2094>`_)
- A bug in the migration script resulting in infinite recursion has been fixed (`!2094 <https://gitlab.com/yaook/k8s/-/merge_requests/2094>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Changelogs of previous releases have been dropped.
  These are still accessible when switching to the respective version.
  From now on, changelogs for each version will be maintained separately and not continously. (`!2094 <https://gitlab.com/yaook/k8s/-/merge_requests/2094>`_)


v9.1.15 (2025-08-25)
--------------------

New Features
~~~~~~~~~~~~

- The following modules of :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module` now do also accept the HTTP status code ``400``:

  * ``http_api_v6``
  * ``http_api_insecure_v6``
  * ``http_api``
  * ``http_api_insecure``

  . (`!2055 <https://gitlab.com/yaook/k8s/-/merge_requests/2055>`_)


Bugfixes
~~~~~~~~

- Allow to configure IPv6-specific modules for blackbox-exporter probes in :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module`.
  Although these modules have been introduced in v9.1.0, they could not be configured until now. (`!2055 <https://gitlab.com/yaook/k8s/-/merge_requests/2055>`_)


v9.1.14 (2025-08-19)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The Thanos image repository has been set to ``bitnamilegacy/thanos`` due to `recent changes by the Bitnami offering <https://github.com/bitnami/containers/issues/83267>`_. (`!1990 <https://gitlab.com/yaook/k8s/-/merge_requests/1990>`_)


v9.1.13 (2025-08-13)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The project has been renamed from YAOOK/K8s to TAROOK.
  The repository location has been updated to reflect this change. (`!2000 <https://gitlab.com/yaook/k8s/-/merge_requests/2000>`_)


Other Tasks
~~~~~~~~~~~

- `!2000 <https://gitlab.com/yaook/k8s/-/merge_requests/2000>`_


v9.1.12 (2025-08-05)
--------------------

Bugfixes
~~~~~~~~

- Cluster setup for IPv6-only clusters has been fixed. (`!1985 <https://gitlab.com/yaook/k8s/-/merge_requests/1985>`_)


v9.1.11 (2025-07-24)
--------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- A new environment group ``yk8s-env.update-inventory`` has been added, so ``update-inventory.sh`` can be run without downloading unnecessary dependencies. (`!1921 <https://gitlab.com/yaook/k8s/-/merge_requests/1921>`_)


v9.1.10 (2025-07-16)
--------------------

Bugfixes
~~~~~~~~~~~~

- The CA rotation procedure has been fixed once again
  including force-renewal of the certificates and kubeconfig on Kubernetes nodes
  and k8s-login for the orchestrator's kubeconfig. (`!1936 <https://gitlab.com/yaook/k8s/-/merge_requests/1936>`_)


v9.1.9 (2025-07-07)
-------------------

New Features
~~~~~~~~~~~~

- Support for audit policies has been added. (`!1896 <https://gitlab.com/yaook/k8s/-/merge_requests/1896>`_)


v9.1.8 (2025-07-03)
-------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Terraform is now disabled by default, which means that for bare-metal clusters it is now sufficient to disable Openstack. This change is non-breaking, because the OpenStack module automatically enabled Terraform. (`!1856 <https://gitlab.com/yaook/k8s/-/merge_requests/1856>`_)


Bugfixes
~~~~~~~~

- A bug has been fixed that resulted in a warning about missing wireguard peers if wireguard was disabled. (`!1856 <https://gitlab.com/yaook/k8s/-/merge_requests/1856>`_)
- The missing options networking_fixed_ip and networking_fixed_ip_v6 have been added to the infra section. (`!1856 <https://gitlab.com/yaook/k8s/-/merge_requests/1856>`_)
- Some option renames have been added to simplify migration of bare-metal clusters. (`!1856 <https://gitlab.com/yaook/k8s/-/merge_requests/1856>`_)
- A bug in the migration script has been fixed that caused the migration to fail if an empty vault state directory existed from a previous failed attempt. (`!1909 <https://gitlab.com/yaook/k8s/-/merge_requests/1909>`_)
- The migration script does not unnecessarily add an openstack section for bare-metal clusters anymore. (`!1909 <https://gitlab.com/yaook/k8s/-/merge_requests/1909>`_)


v9.1.7 (2025-05-07)
-------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- We are now using packages from NixOS stable.
  One reason for that is that we're using boto3 to manage the S3 bucket
  for :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup`,
  but the latest versions of boto3 are `incompatible to OpenStack Swift <https://github.com/boto/botocore/issues/3415>`_. (`!1849 <https://gitlab.com/yaook/k8s/-/merge_requests/1849>`_)


v9.1.6 (2025-04-15)
-------------------

Bugfixes
~~~~~~~~

- A minor bug in the monitoring playbook got fixed
  that caused it to fail
  if no CRD update is needed. (`!1781 <https://gitlab.com/yaook/k8s/-/merge_requests/1781>`_)


v9.1.5 (2025-04-14)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed which caused the deployment of Vault on Kubernetes to incorrectly fail with an external Ingress issuer configured. (`!1803 <https://gitlab.com/yaook/k8s/-/merge_requests/1803>`_)


v9.1.4 (2025-03-27)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed which accidentally applied the Prometheus resource requests and limits :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_resources` also to the operator :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.operator_resources`. (`!1770 <https://gitlab.com/yaook/k8s/-/merge_requests/1770>`_)


v9.1.3 (2025-03-26)
-------------------

Bugfixes
~~~~~~~~

- The default value of option :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.common_labels` has been set to an empty set again such that Prometheus collects all ServiceMonitors by default. (`!1767 <https://gitlab.com/yaook/k8s/-/merge_requests/1767>`_)
- A bug has been fixed which caused an error when applying the Cinder StorageClass in existing clusters running on OpenStack if :ref:`configuration-options.yk8s.openstack.cinder_volume_type` was unset which it is by default. (`!1767 <https://gitlab.com/yaook/k8s/-/merge_requests/1767>`_)
- If specified, :ref:`configuration-options.yk8s.testing.nodes` are now properly used in the test stage. (`!1767 <https://gitlab.com/yaook/k8s/-/merge_requests/1767>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- The option :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.remote_writes.*.basic_auth_secret_name` has been added to documentation. (`!1767 <https://gitlab.com/yaook/k8s/-/merge_requests/1767>`_)


v9.1.2 (2025-03-25)
-------------------

Bugfixes
~~~~~~~~

- Fix IP address autodetection in Calico when used with VRRP on the hosts

  If keepalived was installed on a host, Calico would sometimes incorrectly pick
  the VRRP address as node address. While generally harmless, this could cause
  calico-node to break during/after VRRP failovers because it would then see
  the VRRP address on a different node all of a sudden, leading to a node IP
  address conflict. (`!1752 <https://gitlab.com/yaook/k8s/-/merge_requests/1752>`_)


v9.1.1 (2025-03-25)
-------------------

Bugfixes
~~~~~~~~

- Due to a vulnerability in the ingress-nginx admission controller, ingress-nginx has been updated. (`!1760 <https://gitlab.com/yaook/k8s/-/merge_requests/1760>`_)


v9.1.0 (2025-03-21)
-------------------

New Features
~~~~~~~~~~~~

- Bump Keepalived exporter to version 0.7.1 which introduces IPv6 support
  https://github.com/gen2brain/keepalived_exporter/releases/tag/v0.7.1 (`!1482 <https://gitlab.com/yaook/k8s/-/merge_requests/1482>`_)
- Add IPv6 support for Blackbox exporter (`!1482 <https://gitlab.com/yaook/k8s/-/merge_requests/1482>`_)
- The etcd-metrics-proxy has been adjusted to work on dual stack as well as IPv6 only clusters.

  For dual stack clusters which have been setup prior to release v9.1.0,
  etcd-metrics can be scraped by IPv4 only as etcd must be patched to supply
  metrics on ``[::1]:2381`` as well. Out of the box it supplies metrics only on
  ``127.0.0.1`` even if Kubernetes has been set up to use dual stack.
  This release introduces an automated patch which basically does the following things:

  1. Adjust the ``ClusterConfiguration`` in the ``kubeadm-config`` ConfigMap to reflect the following

    .. code:: yaml

      # [...]
      etcd:
        local:
          extraArgs:
            listen-metrics-urls: "http://127.0.0.1:2381,http://[::1]:2381"
      # [...]

  2. Regenerate the static Pod manifests of etcd on each control plane node with the patched ``ClusterConfiguration``

    .. code:: shell

      $ kubectl get cm kubeadm-config -n kube-system -o json | jq -r .data.ClusterConfiguration > /tmp/cluster-configuration.yaml
      $ kubeadm init phase etcd local --config /tmp/cluster-configuration.yaml

  3. Regenerate the certificates used for TLS encryption between Prometheus and the etcd-metrics-proxy Pods
  4. Restart Prometheus and the etcd-metrics-proxy DaemonSet
  5. Adjust the etcd-metrics-proxy DaemonSet to supply metrics over both IPv4 and IPv6

  The necessary changes are automatically applied on a full rollout.
  To trigger them in a more controlled way, run:

  .. code:: shell

    $ bash managed-k8s/actions/apply-k8s-core.sh install-k8s.yaml
    $ bash managed-k8s/actions/apply-k8s-supplements.sh install-monitoring.yaml

  The above patch is not needed for newly initialized dual stack clusters. (`!1631 <https://gitlab.com/yaook/k8s/-/merge_requests/1631>`_)
- Added support for Kubernetes v1.31 (`!1662 <https://gitlab.com/yaook/k8s/-/merge_requests/1662>`_)
- ``update-inventory.sh`` now passes any arguments given to ``nix build`` (`!1715 <https://gitlab.com/yaook/k8s/-/merge_requests/1715>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- A new env var ``wg_private_key_command`` has been introduced.
  This env var lets the user specify a command that retrieves their
  WireGuard private key from a (safe) place, e.g. from a password
  safe, rather than having it stored in a plain text file or worse,
  stored in an env var directly.

  Both old variables ``wg_private_key`` and ``wg_private_key_file``
  have been deprecated. (`!1609 <https://gitlab.com/yaook/k8s/-/merge_requests/1609>`_)
- Unset options are now rendered to the inventory with an explicit ``null`` value. (`!1687 <https://gitlab.com/yaook/k8s/-/merge_requests/1687>`_)
- Updated default version of helm chart rook-ceph of https://github.com/rook/rook from v1.15.4 to v1.16.5 (`!1700 <https://gitlab.com/yaook/k8s/-/merge_requests/1700>`_)
- Some options have been moved to a better fitting place. (`!1716 <https://gitlab.com/yaook/k8s/-/merge_requests/1716>`_)
- It is now allowed to have :ref:`configuration-options.yk8s.wireguard.enabled` set to ``true`` without any :ref:`configuration-options.yk8s.wireguard.peers` being configured.
  The inventory updater will output a warning though. (`!1737 <https://gitlab.com/yaook/k8s/-/merge_requests/1737>`_)


Bugfixes
~~~~~~~~

- Only deploy Bird ServiceMonitor when the Bird exporter is actually deployed (`!1482 <https://gitlab.com/yaook/k8s/-/merge_requests/1482>`_)
- The ability to limit the test stage to certain nodes has been fixed (`!1690 <https://gitlab.com/yaook/k8s/-/merge_requests/1690>`_)
- A bug has been fixed which prevented the ``install-k8s.yaml`` playbook to succeed if explicitly triggered.

  It is now possible again to execute the following:

  .. code:: console

    ./managed-k8s/actions/apply-k8s-core.sh install-k8s.yaml

  . (`!1741 <https://gitlab.com/yaook/k8s/-/merge_requests/1741>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- A new coding guide line has been added
  to specify that for Ansible builtins
  only the short names shall be used. (`!1696 <https://gitlab.com/yaook/k8s/-/merge_requests/1696>`_)
- Dropped ``libpam-systemd`` from necessary packages for Nix on Ubuntu 24.04. (`!1704 <https://gitlab.com/yaook/k8s/-/merge_requests/1704>`_)
- Advice about making the ``nix-users`` group effective on first setup has been improved. (`!1708 <https://gitlab.com/yaook/k8s/-/merge_requests/1708>`_)
- A note why the binary cache must be configured in ``/etc/nix/nix.conf`` must be configured has been added. (`!1710 <https://gitlab.com/yaook/k8s/-/merge_requests/1710>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- The legacy installation method to deploy FluxCD has been removed. (`!1673 <https://gitlab.com/yaook/k8s/-/merge_requests/1673>`_)


Other Tasks
~~~~~~~~~~~

- `!1676 <https://gitlab.com/yaook/k8s/-/merge_requests/1676>`_, `!1683 <https://gitlab.com/yaook/k8s/-/merge_requests/1683>`_, `!1684 <https://gitlab.com/yaook/k8s/-/merge_requests/1684>`_, `!1685 <https://gitlab.com/yaook/k8s/-/merge_requests/1685>`_, `!1686 <https://gitlab.com/yaook/k8s/-/merge_requests/1686>`_, `!1691 <https://gitlab.com/yaook/k8s/-/merge_requests/1691>`_, `!1697 <https://gitlab.com/yaook/k8s/-/merge_requests/1697>`_, `!1701 <https://gitlab.com/yaook/k8s/-/merge_requests/1701>`_, `!1702 <https://gitlab.com/yaook/k8s/-/merge_requests/1702>`_, `!1707 <https://gitlab.com/yaook/k8s/-/merge_requests/1707>`_, `!1713 <https://gitlab.com/yaook/k8s/-/merge_requests/1713>`_, `!1719 <https://gitlab.com/yaook/k8s/-/merge_requests/1719>`_, `!1721 <https://gitlab.com/yaook/k8s/-/merge_requests/1721>`_, `!1722 <https://gitlab.com/yaook/k8s/-/merge_requests/1722>`_, `!1723 <https://gitlab.com/yaook/k8s/-/merge_requests/1723>`_, `!1724 <https://gitlab.com/yaook/k8s/-/merge_requests/1724>`_, `!1727 <https://gitlab.com/yaook/k8s/-/merge_requests/1727>`_, `!1730 <https://gitlab.com/yaook/k8s/-/merge_requests/1730>`_, `!1732 <https://gitlab.com/yaook/k8s/-/merge_requests/1732>`_, `!1733 <https://gitlab.com/yaook/k8s/-/merge_requests/1733>`_, `!1734 <https://gitlab.com/yaook/k8s/-/merge_requests/1734>`_, `!1740 <https://gitlab.com/yaook/k8s/-/merge_requests/1740>`_


Misc
~~~~

- `!1542 <https://gitlab.com/yaook/k8s/-/merge_requests/1542>`_, `!1640 <https://gitlab.com/yaook/k8s/-/merge_requests/1640>`_, `!1665 <https://gitlab.com/yaook/k8s/-/merge_requests/1665>`_, `!1705 <https://gitlab.com/yaook/k8s/-/merge_requests/1705>`_, `!1720 <https://gitlab.com/yaook/k8s/-/merge_requests/1720>`_
