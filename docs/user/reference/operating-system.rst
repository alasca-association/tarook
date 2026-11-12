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
   Can be used, but may not be fully supported, yet.
   Known issues and breaking changes are possible.
   Not recommended for production clusters.

**Deprecated**
   Support will be discontinued in a future release.
   See the :doc:`/user/explanation/deprecation-policy`.

CPU Architecture
----------------

Tarook only supports the x86_64 (amd64) architecture,
for both gateway nodes and Kubernetes nodes.
Other architectures, such as arm64 (aarch64), are not supported.

Gateway Nodes
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
     - 12 (Bookworm)
     - Known to work
   * - Debian
     - 13 (Trixie)
     - Supported

Kubernetes Nodes
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
     - Deprecated [#calico-ubuntu2204]_
   * - Ubuntu
     - 24.04 LTS (Noble Numbat)
     - Supported
   * - Ubuntu
     - 26.04 LTS (Resolute Raccoon)
     - Supported
   * - Debian
     - 13 (Trixie)
     - Experimental [#k8s-on-debian-13]_

.. important::

    Recent ``kubeadm`` versions have a
    `known issue (#909) <https://gitlab.com/alasca.cloud/tarook/tarook/-/work_items/909>`__
    on operating systems that use ``systemd-resolved``,
    which affects all operating systems listed above.
    Set ``resolvConf`` for ``kubelet`` to ``/run/systemd/resolve/resolv.conf``
    explicitly.
    The recommended place is
    :ref:`configuration-options.yk8s.kubernetes.kubelet.defaultOptions`:

    .. code:: nix

      yk8s.kubernetes.kubelet.defaultOptions = {
        resolvConf = "/run/systemd/resolve/resolv.conf";
      };

    To set it only for some nodes, use
    :ref:`configuration-options.yk8s.kubernetes.kubelet.masterOptions`,
    :ref:`configuration-options.yk8s.kubernetes.kubelet.workerOptions` or
    :ref:`configuration-options.yk8s.kubernetes.kubelet.nodeOptions` instead.

.. [#calico-ubuntu2204]

   Calico v3.32.3 and later in eBPF mode (the default) do not work on Ubuntu 22.04.
   The kernel's BPF verifier rejects Calico's eBPF programs,
   so the ``calico-node`` Pods do not become ready
   and (IPv6) traffic to and from Pods on those nodes fails.

.. [#k8s-on-debian-13]

   Debian 13 support for Kubernetes nodes has been implemented and tested,
   but has not yet been proven in production.
