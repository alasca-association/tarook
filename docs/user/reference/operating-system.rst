.. _supported-operating-systems:

Supported Operating Systems
===========================

This page lists the operating systems Tarook supports for each node type.
Operating systems not listed here are not officially supported.

Tarook distinguishes between the following support levels:

**Supported**
   Tested and maintained by the Tarook project.
   Suitable for production clusters.

**Known to work**
   Known to work and accepted for bug reports, but not covered by automated testing.
   Fixes are provided on a best-effort basis.

**Experimental**
   Can be used, but may not fully covered, yet.
   Known issues and breaking changes are possible.
   Not recommended for production clusters.

Gateway nodes
-------------

Gateway nodes are individual machines running in front of the cluster
when using OpenStack as undercloud.
They act as frontend nodes, see :doc:`/user/explanation/architecture-overview`.

.. list-table::
   :header-rows: 1
   :width: 90%

   * - Operating system
     - Release
     - Support level
   * - Debian
     - 13 (Trixie)
     - Supported
   * - Debian
     - 12 (Bookworm)
     - Known to work

Kubernetes nodes
----------------

This applies to both control plane and worker nodes (including GPU workers).

.. list-table::
   :header-rows: 1
   :width: 90%

   * - Operating system
     - Release
     - Support level
   * - Ubuntu
     - 22.04 LTS (Jammy Jellyfish)
     - Supported [#k8s-with-systemd-resolved]_
   * - Ubuntu
     - 24.04 LTS (Noble Numbat)
     - Supported [#k8s-with-systemd-resolved]_
   * - Ubuntu
     - 26.04 LTS (Resolute Raccoon)
     - Supported [#k8s-with-systemd-resolved]_
   * - Debian
     - 13 (Trixie)
     - Experimental [#k8s-with-systemd-resolved]_ [#k8s-on-debian-13]_

.. [#k8s-with-systemd-resolved]

   There is a `known issue #909 <https://gitlab.com/alasca.cloud/tarook/tarook/-/work_items/909>`__
   with recent ``kubeadm`` versions
   and operating systems using ``systemd-resolved``
   which requires to explicitly set ``resolvConf`` to ``/run/systemd/resolve/resolv.conf``
   for ``kubelet`` via one of the following options:

   * :ref:`configuration-options.yk8s.kubernetes.kubelet.defaultOptions`
   * :ref:`configuration-options.yk8s.kubernetes.kubelet.masterOptions`
   * :ref:`configuration-options.yk8s.kubernetes.kubelet.workerOptions`
   * :ref:`configuration-options.yk8s.kubernetes.kubelet.nodeOptions`

   It is recommended to use :ref:`configuration-options.yk8s.kubernetes.kubelet.defaultOptions`:

   .. code:: nix

      yk8s.kubernetes.kubelet.defaultOptions = {
        resolvConf = "/run/systemd/resolve/resolv.conf";
      };

.. [#k8s-on-debian-13]

   Debian 13 support for Kubernetes nodes has been implemented and tested,
   but not been battle proven in production, yet.
