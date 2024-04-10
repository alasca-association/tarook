Introduction
===================

The yaook/k8s project uses mostly Ansible to provide a customizable, highly available,
scalable and flexible kubeadm-based Kubernetes cluster installation and
lifecycle-management on top of OpenStack or bare-metal.

.. hint::

   If you want to quickly get your cluster up and running, the
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
                           These are either separate nodes or control plane nodes.
   Control Plane Node      The control plane nodes build the Kubernetes control plane
                           and manage the (meta-)workers and Kubernetes objectives in the cluster.
                           More details can be found in the official
                           `k8s docs <https://kubernetes.io/docs/concepts/overview/components/#control-plane-components>`__.
   Meta-Worker             The meta-workers host the management application workload,
                           e.g.  of the :doc:`rook storage solution </managed-services/rook/overview>`
                           or the prometheus-based monitoring stack (more details soon).
   Worker                  The workers host the user application workload.
   ====================    ==============================

Additional Details
~~~~~~~~~~~~~~~~~~

Frontend Nodes
^^^^^^^^^^^^^^

In the case of running on top of OpenStack,
the frontend nodes are the only entry-points into the private network because
they are the only ones holding floating IPs. They may also act as SSH
jumphosts.
Frontend nodes in general are in a hot-standby redundant setup.
The failover is done via
`keepalived <https://keepalived.readthedocs.io/en/latest/index.html>`__.
Each frontend node hosts an instance of
`HAProxy <https://www.haproxy.com/>`__.
HAProxy acts as a load-balancing endpoint for the k8s API server.
This ensures a highly available Kubernetes control plane.
An extra network port is used to hold both, the private and the public
virtual IP (VIP). As a health check, a script queries the ``/healthz``
resource of HAProxy.
Both services are jailed by ``systemd``.

Control Plane Nodes
^^^^^^^^^^^^^^^^^^^

The number of control plane nodes should be uneven (1,3,5, ...), because
k8s uses the Raft protocol.
In order to prevent the split brain problem the majority of nodes has to
be up with 3 control plane nodes, one can fail without problem.
With two out, the last one will stop working because it does not know if
this is just a network partitioning.
Five nodes can handle two failed nodes.

Secrets Management
~~~~~~~~~~~~~~~~~~

The yaook/k8s LCM exclusively uses HashiCorp Vault
as secrets management backend.
For more information, please refer to:
:doc:`/operation/vault`.
