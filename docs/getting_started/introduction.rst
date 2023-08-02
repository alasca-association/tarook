yk8s - Introduction
===================

This project uses mostly Ansible to provide a customizable, highly available,
scalable and flexible kubeadm-based k8s cluster installation and
lifecycle-management on top of OpenStack or bare-metal.

.. hint::

   If you want to get your cluster up and running, the
   :doc:`/getting_started/quick-start` is a good place to begin.

**Main Feature Selling Points**

* Can be deployed on OpenStack or on bare metal
* On OpenStack, self-developed Load-Balancing-as-a-Service solution (no Octavia)
* Nvidia GPU and vGPU Support
* Prometheus-based holistic Monitoring Stack
* Rook-based Ceph Storage
* NGINX Ingress Controller
* Cert-Manager
* Network Policies Support
* etcd-backups
* Flux support

Architecture Overview
---------------------

.. figure:: /img/high-level-architecture.svg
   :scale: 100%
   :alt: High-level Architecture Overview
   :align: center

   High-level Architecture Overview

--------

There are four kinds of host nodes:

.. table::

   ====================    ==============================
   Type                    Short Description
   ====================    ==============================
   Frontend Node           The frontend nodes act as entry point to the Kubernetes Cluster.
                           They are highly available, support load-balancing and act as a firewall.
   Control Plane Node      The control plane nodes build the k8s control
                           plane manage the (meta-)workers and the Pods in the cluster.
                           More details can be found in the official
                           `k8s docs <https://kubernetes.io/docs/concepts/overview/components/#control-plane-components>`__.
   Meta-Worker             The meta-workers host the management application workload,
                           e.g.  of the :doc:`rook storage solution </managed-services/rook/overview>`
                           or the prometheus-based monitoring stack (more details soon).
   Worker                  The workers host the user application workload.
   ====================    ==============================


.. note::

   A control plane node can also act as a frontend node.

Additional Details
~~~~~~~~~~~~~~~~~~

Frontend Nodes
^^^^^^^^^^^^^^

Frontend nodes are the only entry-points into the private network because
they are the only ones holding floating IPs. They may also act as SSH
jumphosts. Frontend nodes are made redundant via
`keepalived <https://keepalived.readthedocs.io/en/latest/index.html>`__.
Each frontend node hosts an instance of
`HAProxy <https://www.haproxy.com/>`__.
HAProxy acts as a load-balancing endpoint for the k8s API server.
An extra network port is used to hold both, the private and the public
virtual IP (VIP). As a health check, a script queries the ``/healthz``
resource of HAProxy.
Both services run in containers for isolation.
However, they might be jailed by ``systemd`` in the future instead.

Control Plane Nodes
^^^^^^^^^^^^^^^^^^^

The number of control plane nodes should be uneven (1,3,5, ...), because
k8s uses the Raft protocol.
In order to prevent the split brain problem the majority of nodes has to
be up with 3 control plane nodes, one can fail without problem.
With two out, the last one will stop working because it does not know if
this is just a network partitioning.
Five nodes can handle two failed nodes.
