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

v13.0.0 (2026-04-21)
--------------------

Breaking changes
~~~~~~~~~~~~~~~~

- Common names for certificates issued by HashiCorp Vault
  are now prevented from being treated as domain names during validation.

  This change requires a Vault policy update (backwards-compatible).

  .. attention:: Action required

     .. code:: shell

        VAULT_TOKEN=${vault_root_token:?} ./managed-k8s/tools/vault/init.sh

  _ (`!2254 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2254>`_)
- The KUBECONFIG variable is now set by our direnv layout "yaook-k8s". The migration script will remove our previous default from your .envrc. If you've customized the definition, it won't be touched. (`!2274 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2274>`_)
- For development setups with a local Vault container,
  the Vault certificates must be removed and regenerated
  as newer Ansible versions enforce the usage of a key extension
  which was not included in the Vault development setup until now.

  The only clean way to achieve that is to setup a complete new cluster repository for your development setup. (`!2289 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2289>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 78.5.0 to 82.0.0 (`!2301 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2301>`_)
- Updated default version of helm chart etcdbackup from 1.4.1 to 2.0.0 (`!2407 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2407>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 82.15.0 to 83.0.0 (`!2419 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2419>`_)


New Features
~~~~~~~~~~~~

- Options for flexible kubelet configuration have been added.
  These options can be applied at various levels of granularity:

  * For all nodes: :ref:`configuration-options.yk8s.kubernetes.kubelet.defaultOptions`
  * For worker nodes only: :ref:`configuration-options.yk8s.kubernetes.kubelet.workerOptions`
  * For master nodes only: :ref:`configuration-options.yk8s.kubernetes.kubelet.masterOptions`
  * For specific nodes: :ref:`configuration-options.yk8s.kubernetes.kubelet.nodeOptions`

  . (`!1910 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1910>`_)
- Retries have been added to Kubernetes API calls to further improve resilience. (`!2289 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2289>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The ``nixpkgs.url`` has been changed from 25.05 to 25.11. (`!2289 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2289>`_)
- kubelets are configured now such that up to three images are pulled in parallel by default. (`!2289 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2289>`_)
- The Ansible plays have been made compatible with `Ansible 12 <https://docs.ansible.com/projects/ansible/12/porting_guides/porting_guide_12.html#ansible-12-porting-guide>`__. (`!2289 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2289>`_, `!2448 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2448>`_)
- Updated default version of helm chart tigera-operator of https://github.com/projectcalico/calico from v3.30.6 to v3.31.4 (`!2307 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2307>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.14.5 to 4.15.1 (`!2333 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2333>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.19.4 to v1.20.0 (`!2334 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2334>`_)
- Nodes already being cordoned before a rollout
  are not automatically uncordoned on system or Kubernetes upgrades anymore. (`!2362 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2362>`_)
- Updated default version of helm chart vault of https://helm.releases.hashicorp.com from 0.23.0 to 0.25.0.
  This results in an upgrade of HashiCorp Vault from 1.12.1 to 1.14.0.

  .. attention:: Action required

     Rolling out the new Helm chart version
     only updates the ``vault`` StatefulSet,
     but **not** the replica Pods.

     Refer to :doc:`/user/guide/vault/upgrade` for the additional steps necessary.

  _ (`!2363 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2363>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.8.0 to 11.9.0 (`!2387 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2387>`_)
- Updated default version of helm chart etcdbackup from 1.4.0 to 1.4.1 (`!2388 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2388>`_)
- The kube-prometheus-stack Helm chart's automatic CRD upgrade job option has been enabled.
  It is now enforced that :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_stack_version` is set to at least ``68.4.0``. (`!2392 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2392>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 82.0.0 to 82.13.0 (`!2393 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2393>`_)
- For clusters running on OpenStack,
  the VolumeSnapshotClass ``csi-cinder-snapclass`` has been adapted such that
  snapshots of attached (in-use) Cinder volumes are allowed.
  It is still highly recommended to snapshot detached volumes only,
  as snapshots of attached volumes are not guaranteed to be application-consistent. (`!2394 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2394>`_)
- Updated default version of helm chart rook-ceph of https://github.com/rook/rook from v1.18.9 to v1.18.10 (`!2403 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2403>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 82.13.0 to 82.15.0 (`!2408 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2408>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.20.0 to v1.20.1 (`!2409 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2409>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.9.0 to 11.9.1 (`!2412 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2412>`_)
- Updated default version of helm chart etcdbackup from 2.0.0 to 2.0.1 (`!2415 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2415>`_)
- The `helm diff <https://github.com/databus23/helm-diff>`__ plugin has been added to the default devShell. (`!2420 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2420>`_)
- Updated default version of helm chart kube-prometheus-stack of https://github.com/prometheus-community/helm-charts from 83.0.0 to 83.4.0 (`!2426 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2426>`_)
- Updated default version of helm chart etcdbackup from 2.0.1 to 2.0.2 (`!2430 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2430>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.20.1 to v1.20.2 (`!2435 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2435>`_)
- Updated default version of helm chart tigera-operator of https://github.com/projectcalico/calico from v3.31.4 to v3.31.5 (`!2436 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2436>`_)


Bugfixes
~~~~~~~~

- An off-by-one-error in the kube-prometheus-stack upgrade procedure has been fixed. (`!2289 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2289>`_)
- A bug has been fixed in the :doc:`/user/guide/vault/vault-ca-rotation`,
  which caused it to fail in phase 1 if :ref:`configuration-options.yk8s.kubernetes.controller_manager.enable_signing_requests`
  is enabled. (`!2289 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2289>`_)
- A bug has been fixed where, when running a Kubernetes upgrade, the maximum pod limit for control plane nodes was temporarily reset to 110. (`!2325 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2325>`_)
- The value of :ref:`configuration-options.yk8s.wireguard.endpoints.*.port`
  is now enforced to be unique across all Wireguard endpoints. (`!2364 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2364>`_)
- Fixed a bug that prevented the cleanup of IPSec
  when :ref:`configuration-options.yk8s.ipsec.enabled` was set to ``false``. (`!2378 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2378>`_)
- Added missing IPSec cleanup tasks. (`!2378 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2378>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Added a guide to setting up automatic Vault backups,
  see :doc:`/user/guide/vault/automatic-backups`. (`!2363 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2363>`_)


Other Tasks
~~~~~~~~~~~

- `!2190 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2190>`_, `!2380 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2380>`_, `!2385 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2385>`_, `!2390 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2390>`_, `!2404 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2404>`_, `!2405 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2405>`_, `!2410 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2410>`_, `!2429 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2429>`_, `!2431 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2431>`_, `!2439 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2439>`_


Misc
~~~~

- `!2338 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2338>`_, `!2437 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2437>`_
