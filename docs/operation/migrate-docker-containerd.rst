Migrate CRI from docker to containerd
=====================================

.. note::
   You must migrate to containerd **prior** to upgrading to
   Kubernetes v1.24 as Kubernetes
   `dropped support for dockershim <https://kubernetes.io/blog/2022/03/31/ready-for-dockershim-removal/>`__.


The process of changing the CRI from docker to containerd is well
documented in the official Kubernetes documentation:
`Changing the Container Runtime on a Node from Docker Engine to containerd <https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/>`__.

Migration
---------

The migration can be triggered via:

.. code:: console

   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/migrate-docker-containerd.sh [-s]

After the playbook finished, one **must** change the
``container_runtime`` variable to ``containerd`` in its
``config/config.toml``.

Procedure Description
---------------------

This section gives a brief overview about which steps have been
implemented to migrate from docker to containerd in the respective
:ref:`action script <actions-references.migrate-docker-containerdsh>`.

First, connectivity to the nodes is established. After that, each node
gets processed in serial. It is ensured that the container runtime is
:ref:`configured correctly <cluster-configuration.miscellaneous-configuration>`.

For each node, the following steps are taken:

-  Check if the node already uses containerd as container runtime, all
   following steps are skipped if that’s the case.
-  Ensure the cluster is healthy. This can be
   :ref:`skipped <migrate-docker-containerd.skip-intermediate-cluster-health-verification>`.
-  Drain the node
-  System update the node

   -  As the node is drained, this is a good point in time to throw in a
      system update

-  Stop ``kubelet``
-  Stop and disable docker
-  Install containerd
-  Configure ``kubelet`` to use containerd as CRI.
-  Restart ``kubelet``
-  Patch the respective node annotation.

   -  As we’re using ``kubeadm`` to build our Kubernetes cluster and
      ``kubeadm`` annotates the node with the respective container
      runtime, we need to patch that annotation.

-  Verify that the container runtime of the node is containerd now.
-  Remove docker engine from the node.
-  Restart ``kubelet``.

   -  Another restart of ``kubelet`` is needed after removing the docker
      engine.

-  Uncordon the node

After each node has been processed and the playbook finished
successfully, one **must** change the
:ref:`container runtime variable <cluster-configuration.miscellaneous-configuration>`
in its ``config/config.toml`` to ``containerd`` before continuing with
further operations.

.. _migrate-docker-containerd.skip-intermediate-cluster-health-verification:

Skip intermediate Cluster Health Verification
---------------------------------------------

Obviously, changing the container runtime for a node is considered
disruptive. Nodes get migrated in serial (one after another). In-between
the single migration of each node , the
``cluster_health_verification``-role is executed. This role contains
tasks to verify the cluster has converged before tainting & draining the
next node.

These intermediate tasks can be circumvented by passing ``-s`` to the
``upgrade.sh``:ref:`-script <actions-references.upgradesh>`.
The flag has to be passed between the script path and the target
version. Skipping the health verification tasks is not recommended.

.. code:: console

   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/migrate-docker-containerd.sh [-s]
