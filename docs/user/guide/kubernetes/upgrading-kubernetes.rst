Upgrading Kubernetes
====================

Upgrade implications / disruptions
----------------------------------

-  All pods will be rescheduled at least once, sometimes more often
-  All pods without a controller will be deleted
-  Data in emptyDir volumes will be lost
-  (if enabled) Ceph storage will be blocking/unavailable for the
   duration of the upgrade

General procedure
-----------------

1. Agree on a time window with the customer. Make sure they are aware of
   the disruptions.

2. Ensure that the cluster is healthy. All pods managed by us should be
   Running or Completed. Pods managed by the customer should also be in
   such states; but if they are not, there’s nothing we can do about it.

3. Execute the upgrade playbook from within the cluster repository:

   .. code:: console

      $ MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.x.y

4. Once the upgrade executed successfully, update your ``config.toml``
   to point to the new k8s version:

   .. code:: toml

      [kubernetes]
      version="1.x.y"

Skip Intermittent Cluster Health Verification
---------------------------------------------

Simply said, during a Kubernetes upgrade, all nodes get tainted,
upgraded and uncordoned. The nodes do get processed quickly one after
another. In between the node upgrades, the
``cluster_health_verification``-role is executed. This role contains
tasks to verify the cluster has converged before tainting the next node.

These intermediate tasks can be circumvented by passing ``-s`` to the
``upgrade.sh``:ref:`-script <actions-references.upgradesh>`.
The flag has to be passed between the script path and the target
version.

.. code:: console

   $ # Triggering a Kubernetes upgrade and skip health verification tasks
   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh -s 1.22.11

Kubernetes Component Versioning
-------------------------------

General Information
~~~~~~~~~~~~~~~~~~~

In general, we’re mapping the versions of components which are essential
for Kubernetes to properly work to the Kubernetes version in the
``k8s-config`` `role <https://gitlab.com/yaook/k8s/-/blob/devel/k8s-base/roles/k8s-config/defaults/main.yaml#L31>`__.

All versions of non-essential components are not mapped to the
Kubernetes version, i.e. all components/services above the Kubernetes
layer itself.

Calico
~~~~~~

The calico version is mapped to the Kubernetes version and calico is
updated to the mapped version during Kubernetes upgrades. However, it is
possible to manually update calico to another version. That procedure is
describe in :doc:`calico </user/explanation/services/calico>`.
