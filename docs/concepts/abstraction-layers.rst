******************
Abstraction Layers
******************

.. _abstraction-layers.k8s-core:

Software
========

|

.. figure:: ../img/layer-hierarchy.svg
  :alt: TODO
  :align: center

  High-level abstraction of software modules which make up the LCM.

|

The yaook/k8s life-cycle-management tooling can be abstracted into two main modules:
k8s-core and k8s-supplements.

k8s-core
--------

The so-called k8s-core consists of Ansible playbooks
which automate and allow the bootstrapping, preparation, configuration and customization
of nodes to fulfill the requirements for a high-available Kubernetes cluster as well
as the initialization and maintenance of a "vanilla" `kubeadm`-based Kubernetes cluster.

.. _abstraction-layers.k8s-supplements:

k8s-supplements
---------------

The so-called k8s-supplements consists of Ansible playbooks
which complement the very rudimentary Kubernetes cluster initialized by the k8s-core
and adds necessary as well as optional but useful surroundings for a
fully functional productive Kubernetes environment.

.. _abstraction-layers.customization:

Customization
-------------

In order to allow users to use a kind of extensions or additional plays,
a drop-in directory is created if enabled which can be used to
include custom tasks to the cluster-repository. These plays are
automatically executed and are on the top of the abstraction layer as
they rely on a working yk8s cluster.

The customization layer is enabled by default
but can be disabled via
:ref:`an environment variable <environmental-variables.enabling-the-customization-layer>`.

Architecture
============

|

.. figure:: ../img/high-level-architecture.svg
  :alt: TODO
  :align: center

  High-level architectural abstraction of a yaook/k8s cluster.

|

Harbour Infrastructure Layer / Undercloud
-----------------------------------------

What we internally call harbor infrastructure layer is
generally better known as undercloud and
describes the system on which the Kubernetes is deployed.
A yaook/k8s-cluster can be built upon an already existing
OpenStack deployment or directly on bare metal.

In general, network configuration aside,
the yaook/k8s-LCM requires layer 3 access
to a bunch of nodes ideally freshly set up.

yk8s on OpenStack
~~~~~~~~~~~~~~~~~

If the Kubernetes cluster runs on top of OpenStack,
it has to be connected to the OpenStack layer.
On each control plane node, an OpenStack cloud controller manager (CCM)
is running that acts as an interface between the cluster and OpenStack.
``kubelet`` is started with ``--cloud-provider=external``.
Block storage can be dynamically provisioned by OpenStack Cinder via the
Cinder Container Storage Interface (CSI) plugin.

yk8s on Bare Metal
~~~~~~~~~~~~~~~~~~

The Kubernetes cluster can also run directly on bare metal nodes.
We differentiate two different scenarios,
the bare metal nodes are self-managed
or by the `yaook/metal-controller <https://gitlab.com/yaook/metal-controller>`_
is used to provision the nodes and the Kubernetes running on them.

Self-managed Bare Metal
^^^^^^^^^^^^^^^^^^^^^^^

The yaook/k8s LCM assumes that you have L3-connectivity to a bunch of nodes.
It does not really matter if these are bare metal nodes or VMs on a cloud.

Automated Bare Metal
^^^^^^^^^^^^^^^^^^^^

For further information, please refer to the
`yaook/metal-controller <https://gitlab.com/yaook/metal-controller>`_
