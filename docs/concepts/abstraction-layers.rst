Abstraction Layers
==================

.. todo::
   
   This document needs more details!


.. figure:: /img/layer-hierarchy.svg
   :scale: 100%
   :alt: Layer Hierarchy Overview Visualization
   :align: center

|

.. _abstraction-layers.customization:

Customization
-------------

In order to allow users to use a kind of extensions or additional plays,
a drop-in directory is created if enabled so which can be used to
include custom tasks to the cluster-repository. These plays are
automatically executed and are on the top of the abstraction layer as
they rely on a working yk8s cluster.

The customization layer can be enabled via
:ref:`an environment variable <envirnomental-variables.enabling-the-customization-layer>`.

KMS - Kubernetes Managed Services
---------------------------------

The KMS layer sets up and manages Kubernetes resources and services
which are specifically and only necessary for the deployment of an
(automatically) managed yk8s-Cluster on top of OpenStack.

KSL - Kubernetes Service Layer
------------------------------

The KSL is the intermediate “service layer”, which introduces APIs and
k8s features which are not part of a chocolate k8s cluster but which may
still be useful/commonly used. This includes cert manager, ingress,
ceph/rook as well as a basic prometheus-based monitoring stack.

.. _abstraction-layers.k8s-base:

k8s-base
--------

This layer prepares, initializes, configures and maintains the
kubeadm-based chocolate Kubernetes cluster. On this layer, the provided
Kubernetes cluster will contain only necessary services. As this layer
includes the management of the Kubernetes cluster, it is also the place
for general actions against and with it, like e.g. upgrading to a newer
Kubernetes version, adding nodes, or tearing it down. Note that this
layer does not only interact with the control plane and (meta-)worker
nodes, but also does some configuration to the frontend nodes.

Trampoline
----------

This layer prepares and manages the basic frontend node setup. This
includes SSH access, load-balancing, high availability, VPN and firewall
setup and management. Kubernetes-cluster-specific configuration of these
services happens in the :ref:`k8s-base <abstraction-layers.k8s-base>` layer.

Harbour Infrastructure Layer
----------------------------

A yk8s-cluster can be built upon an (existing) OpenStack deployment or
on Bare Metal.

yk8s on OpenStack
~~~~~~~~~~~~~~~~~

On each control plane node, an OpenStack cloud controller manager (CCM)
is running that acts as an interface between the cluster and OpenStack.
``kubelet`` is started with ``--cloud-provider=external``. Block storage
can be dynamically provisioned by OS cinder via the Cinder Container
Storage Interface (CSI) plugin.

yk8s on Bare Metal
~~~~~~~~~~~~~~~~~~

.. todo::
   
   Merge information from
   `incubator/installation-guide!5 <https://gitlab.com/yaook/incubator/installation-guide/-/merge_requests/5/>`__

Self-managed Bare Metal
^^^^^^^^^^^^^^^^^^^^^^^

Automated Bare Metal
^^^^^^^^^^^^^^^^^^^^
