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

v16.0.0 (2026-11-12)
--------------------

Breaking Changes
~~~~~~~~~~~~~~~~

- Updated default version of helm chart flux2 of https://github.com/fluxcd-community/helm-charts from 2.16.4 to 2.18.4

  .. important::

     The flux2 chart v2.18.4 ships Flux v2.8.8.

     Flux v2.7 and v2.8 `removed several deprecated beta APIs <https://github.com/fluxcd/flux2/discussions/5572>`__,
     e.g. ``helm.toolkit.fluxcd.io/v2beta2`` and ``kustomize.toolkit.fluxcd.io/v1beta2``.
     Flux resources already stored in the cluster are migrated automatically
     by a pre-upgrade hook when the chart is upgraded.

     .. note::

        If you want to upgrade from a version <2.16.4 you must manually run ``flux migrate`` against the cluster
        before doing so.

     Manifests you apply yourself (e.g. from Git) must be updated to the
     stable API versions before upgrading, otherwise they will be rejected.
     ``flux migrate -v 2.6 -f <path>`` rewrites them for you.

     ``image.toolkit.fluxcd.io/v1beta2`` and ``notification.toolkit.fluxcd.io/v1beta2``
     still work with this release but will be removed in Flux v2.9.
     Migrate them after upgrading with ``flux migrate -v 2.8 -f <path>``.

     **Do not skip the release v2.18.4 before upgrading to a later one.**

  _ (`!2281 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2281>`_)


Changed Functionality
~~~~~~~~~~~~~~~~~~~~~

- The HAProxy health check for the kube-apiservers now uses ``/readyz``.
  A kube-apiserver which cannot reach its etcd member is now taken out of the load balancing and existing connections to it are closed.
  Previously, requests to such a kube-apiserver hung,
  which could cause repeated leader election failures of kube-controller-manager and kube-scheduler. (`!2703 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2703>`_)
- The Kubernetes repository is configured as a deb822 ``.sources`` file now. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)
- The Nvidida driver packages on Ubuntu are updated to the latest point release on a
  :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`
  or
  :ref:`system update<actions-references.update-kubernetes-nodessh>`.
  Previously, the installed point release was kept and never got updated. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)
- The nvidia-container-toolkit repository is configured as a deb822 ``.sources`` file now.
  For existing nodes, this change takes effect on the next
  :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`
  or
  :ref:`system update<actions-references.update-kubernetes-nodessh>`. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)
- The Nvidia CUDA repository is configured as a deb822 ``.sources`` file now.
  For existing nodes, this change takes effect on the next
  :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`
  or
  :ref:`system update<actions-references.update-kubernetes-nodessh>`. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)
- The containerd repository is configured as a deb822 ``.sources`` file now.
  For existing nodes, this change takes effect on the next
  :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`
  or
  :ref:`system update<actions-references.update-kubernetes-nodessh>`. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)
- The Hashicorp repository is configured as a deb822 ``.sources`` file now. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)


Dependencies
~~~~~~~~~~~~

- Updated default version of helm chart crd.projectcalico.org.v1 of https://github.com/projectcalico/calico from v3.32.1 to v3.32.2 (`!2687 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2687>`_)
- Updated default version of helm chart cert-manager of https://github.com/cert-manager/cert-manager from v1.20.4 to v1.20.5 (`!2712 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2712>`_)


Bugfixes
~~~~~~~~

- Fix reachability of Vault on Kubernetes in IPv4-only setups where the IPv6 stack is completely absent. (`!2680 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2680>`_)
- The dependencies have been updated in order to fix `CVE-2026-111943 "eMudhra Intermediate CA Compromise" <https://gitlab.com/groups/alasca.cloud/tarook/-/work_items/1>`__ (`!2717 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2717>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- containerd is now by default configured to discard downloaded image layers after they have been unpacked,
  see :ref:`configuration-options.yk8s.containerd.discard_unpacked_layers`. (`!2704 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2704>`_)
- Added a preface to :ref:`configuration-options.yk8s.containerd` to make clear under which conditions configuration changes take effect. (`!2704 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2704>`_)
- :doc:`/user/reference/operating-system` are now listed in the documentation. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)
- The :doc:`/user/explanation/deprecation-policy` document has been updated. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Support for Kubernetes v1.33 has been dropped. (`!2700 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2700>`_)
- Support for Ubuntu 22.04 on Kubernetes nodes has been marked as deprecated,
  see :ref:`supported-operating-systems`.
  Please migrate affected nodes to Ubuntu 24.04, 26.04 or Debian 13. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)
- The configuration option ``yk8s.miscellaneous.apt_proxy_url`` has been removed.
  Since v4.0.0, it did not configure an APT proxy anymore,
  but only switched the Docker, Kubernetes and HashiCorp package repositories from HTTPS to HTTP.
  These repositories are always accessed via HTTPS now.
  If your configuration still sets the option, remove it. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)


Other Tasks
~~~~~~~~~~~

- The CI/CD pipeline now uses Debian 13 images for one control plane node and the GPU worker. (`!2725 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2725>`_)


Misc
~~~~

- `!2706 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2706>`_, `!2707 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2707>`_
