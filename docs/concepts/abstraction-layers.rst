Abstraction Layers
==================

Harbour Infrastructure Layer / Undercloud
-----------------------------------------

A yaook/k8s-cluster can be built upon an (existing) OpenStack deployment or
on Bare Metal.

yk8s on OpenStack
~~~~~~~~~~~~~~~~~

If the Kubernetes cluster runs on top of OpenStack,
it has to be connected to the OpenStack layer.
On each control plane node, an OpenStack cloud controller manager (CCM)
is running that acts as an interface between the cluster and OpenStack.
``kubelet`` is started with ``--cloud-provider=external``.
Block storage can be dynamically provisioned by OS cinder via the
Cinder Container Storage Interface (CSI) plugin.

yk8s on Bare Metal
~~~~~~~~~~~~~~~~~~

The Kubernetes cluster can also run directly on bare metal nodes.
We differentiate two different scenarios,
the bare metal nodes are self-managed or the `yaook/metal-controller <https://gitlab.com/yaook/metal-controller>`
is used to provision the nodes and the Kubernetes running on them.

Self-managed Bare Metal
^^^^^^^^^^^^^^^^^^^^^^^

The yaook/k8s LCM assumes that you have L3-connectivity to a bunch of nodes.
It does not really matter if these are bare metal nodes or VMs on a cloud.

Automated Bare Metal
^^^^^^^^^^^^^^^^^^^^

For further information, please refer to the
`yaook/metal-controller <https://gitlab.com/yaook/metal-controller>`

.. _abstraction-layers.k8s-core:

k8s-core
--------

.. _abstraction-layers.k8s-supplements:

k8s-supplements
---------------

.. _abstraction-layers.customization:

Customization
-------------

In order to allow users to use a kind of extensions or additional plays,
a drop-in directory is created if enabled so which can be used to
include custom tasks to the cluster-repository. These plays are
automatically executed and are on the top of the abstraction layer as
they rely on a working yk8s cluster.

The customization layer can be enabled via
:ref:`an environment variable <environmental-variables.enabling-the-customization-layer>`.