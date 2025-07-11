.. _configuration-options.yk8s.k8s-service-layer.rook:

yk8s.k8s-service-layer.rook
^^^^^^^^^^^^^^^^^^^^^^^^^^^


The used rook setup is explained in more detail
:doc:`here </user/explanation/services/rook-storage>`.

.. note::

  To enable rook in a cluster on top of OpenStack, you need
  to set both :ref:`configuration-options.yk8s.k8s-service-layer.rook.nosds` and
  ``k8s-service-layer.rook.osd_volume_size``, as well as enable
  :ref:`configuration-options.yk8s.k8s-service-layer.rook.enabled` and either
  :ref:`configuration-options.yk8s.kubernetes.local_storage.dynamic.enabled` or
  :ref:`configuration-options.yk8s.kubernetes.local_storage.static.enabled` local
  storage (or both).

.. _cluster-configuration.rook-configuration.updating-immutable-options:

Updating immutable options
**************************

Some options are immutable when deployed.
If you want to change them nonetheless, follow these manual steps:
1. Increase the size of the corresponding PVC
2. Delete the stateful set: ``kubectl delete -n monitoring sts --cascade=false <statefulset_name>``
3. Re-deploy it with the LCM: ``AFLAGS="--diff --tags rook --tags rook_v2" bash managed-k8s/actions/apply-k8s-supplements.sh``

.. _configuration-options.yk8s.k8s-service-layer.rook.ceph_fs:

``yk8s.k8s-service-layer.rook.ceph_fs``
#######################################

Whether to enable the CephFS shared filesystem.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.ceph_fs_name:

``yk8s.k8s-service-layer.rook.ceph_fs_name``
############################################



**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "ceph-fs"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.ceph_fs_preserve_pools_on_delete:

``yk8s.k8s-service-layer.rook.ceph_fs_preserve_pools_on_delete``
################################################################

Whether to enable preservation of pools on delete.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.ceph_fs_replicated:

``yk8s.k8s-service-layer.rook.ceph_fs_replicated``
##################################################



**Type:**::

  positive integer, meaning >0


**Default:**::

  1


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.cluster_name:

``yk8s.k8s-service-layer.rook.cluster_name``
############################################



**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "rook-ceph"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.csi_plugins:

``yk8s.k8s-service-layer.rook.csi_plugins``
###########################################

Set to false to disable CSI plugins, if they are not needed in the rook cluster.
(For example if the ceph cluster is used for an OpenStack cluster)


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.custom_ceph_version:

``yk8s.k8s-service-layer.rook.custom_ceph_version``
###################################################

Configure a custom Ceph version.
If not defined, the one mapped to the rook version
will be used. Be aware that you can't choose an
arbitrary Ceph version, but should stick to the
rook-ceph-compatibility-matrix.


**Type:**::

  null or OCI image tag


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.dashboard:

``yk8s.k8s-service-layer.rook.dashboard``
#########################################

Whether to enable the ceph dashboard for viewing cluster status
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.enabled:

``yk8s.k8s-service-layer.rook.enabled``
#######################################

Whether to enable Rook.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.encrypt_osds:

``yk8s.k8s-service-layer.rook.encrypt_osds``
############################################

Whether to enable encryption of OSDs.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.helm_release_name_cluster:

``yk8s.k8s-service-layer.rook.helm_release_name_cluster``
#########################################################



**Type:**::

  Helm chart release name


**Default:**::

  "rook-ceph-cluster"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.helm_release_name_operator:

``yk8s.k8s-service-layer.rook.helm_release_name_operator``
##########################################################



**Type:**::

  Helm chart release name


**Default:**::

  "rook-ceph"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.manage_pod_budgets:

``yk8s.k8s-service-layer.rook.manage_pod_budgets``
##################################################

If true, the rook operator will create and manage PodDisruptionBudgets
for OSD, Mon, RGW, and MDS daemons.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mds_resources:

``yk8s.k8s-service-layer.rook.mds_resources``
#############################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mds_resources.limits.cpu:

``yk8s.k8s-service-layer.rook.mds_resources.limits.cpu``
########################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mds_resources.limits.memory:

``yk8s.k8s-service-layer.rook.mds_resources.limits.memory``
###########################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "4Gi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mds_resources.requests.cpu:

``yk8s.k8s-service-layer.rook.mds_resources.requests.cpu``
##########################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mds_resources.requests.memory:

``yk8s.k8s-service-layer.rook.mds_resources.requests.memory``
#############################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.rook.mds_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mgr_resources:

``yk8s.k8s-service-layer.rook.mgr_resources``
#############################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mgr_resources.limits.cpu:

``yk8s.k8s-service-layer.rook.mgr_resources.limits.cpu``
########################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mgr_resources.limits.memory:

``yk8s.k8s-service-layer.rook.mgr_resources.limits.memory``
###########################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "512Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mgr_resources.requests.cpu:

``yk8s.k8s-service-layer.rook.mgr_resources.requests.cpu``
##########################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mgr_resources.requests.memory:

``yk8s.k8s-service-layer.rook.mgr_resources.requests.memory``
#############################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.rook.mgr_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mgr_scheduling_key:

``yk8s.k8s-service-layer.rook.mgr_scheduling_key``
##################################################

Additionally it is possible to schedule mons and mgrs pods specifically.
NOTE: Rook does not merge scheduling rules set in 'all' and the ones in 'mon' and 'mgr',
but will use the most specific one for scheduling.


**Type:**::

  null or Kubernetes label


**Default:**::

  null


**Example:**::

  "${scheduling_key_prefix}/rook-mgr"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mgr_use_pg_autoscaler:

``yk8s.k8s-service-layer.rook.mgr_use_pg_autoscaler``
#####################################################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_allow_multiple_per_node:

``yk8s.k8s-service-layer.rook.mon_allow_multiple_per_node``
###########################################################



**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_resources:

``yk8s.k8s-service-layer.rook.mon_resources``
#############################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_resources.limits.cpu:

``yk8s.k8s-service-layer.rook.mon_resources.limits.cpu``
########################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_resources.limits.memory:

``yk8s.k8s-service-layer.rook.mon_resources.limits.memory``
###########################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "1Gi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_resources.requests.cpu:

``yk8s.k8s-service-layer.rook.mon_resources.requests.cpu``
##########################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_resources.requests.memory:

``yk8s.k8s-service-layer.rook.mon_resources.requests.memory``
#############################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.rook.mon_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_scheduling_key:

``yk8s.k8s-service-layer.rook.mon_scheduling_key``
##################################################

Additionally it is possible to schedule mons and mgrs pods specifically.
NOTE: Rook does not merge scheduling rules set in 'all' and the ones in 'mon' and 'mgr',
but will use the most specific one for scheduling.


**Type:**::

  null or Kubernetes label


**Default:**::

  null


**Example:**::

  "${scheduling_key_prefix}/rook-mon"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_volume:

``yk8s.k8s-service-layer.rook.mon_volume``
##########################################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_volume_size:

``yk8s.k8s-service-layer.rook.mon_volume_size``
###############################################

Immutable when deployed. (See also :ref:`cluster-configuration.rook-configuration.updating-immutable-options`)


**Type:**::

  Kubernetes quantity


**Default:**::

  "10Gi"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.mon_volume_storage_class:

``yk8s.k8s-service-layer.rook.mon_volume_storage_class``
########################################################

Storage class name to be used by the ceph mons. SHOULD be compliant with one
storage class you have configured in the kubernetes.local_storage section (or
you should know what your are doing). Note that this is not the storage class
name that rook will provide.

Immutable when deployed. (See also :ref:`cluster-configuration.rook-configuration.updating-immutable-options`)


**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "\${kubernetes.local_storage.dynamic.storageclass_name}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.namespace:

``yk8s.k8s-service-layer.rook.namespace``
#########################################

Namespace to deploy the rook in (will be created if it does not exist, but
never deleted).


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "rook-ceph"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nmgrs:

``yk8s.k8s-service-layer.rook.nmgrs``
#####################################

Number of mgrs to run. Default is 1 and can be extended to 2
and achieve high-availability.
The count of mgrs is adjustable since rook v1.6 and does not work with older versions.


**Type:**::

  integer between 1 and 2 (both inclusive)


**Default:**::

  2


**Example:**::

  1


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nmons:

``yk8s.k8s-service-layer.rook.nmons``
#####################################

Number of mons to run.
Default is 3 and is the minimum to ensure high-availability!
The number of mons has to be uneven.


**Type:**::

  positive integer, meaning >0


**Default:**::

  3


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nodeplugin_toleration:

``yk8s.k8s-service-layer.rook.nodeplugin_toleration``
#####################################################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nodes:

``yk8s.k8s-service-layer.rook.nodes``
#####################################

You do also have the option to manually define the nodes to be used,
their configuration and devices of the configured nodes as well as
device-specific configurations. For these configurations to take effect
one must set :ref:`configuration-options.yk8s.k8s-service-layer.rook.use_all_available_devices` and
:ref:`configuration-options.yk8s.k8s-service-layer.rook.use_all_available_nodes` to ``false``.

See :doc:`/user/guide/rook/custom-storage`


**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nodes.*.config:

``yk8s.k8s-service-layer.rook.nodes.*.config``
##############################################



**Type:**::

  attribute set


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nodes.*.devices:

``yk8s.k8s-service-layer.rook.nodes.*.devices``
###############################################



**Type:**::

  attribute set of (submodule)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nodes.*.devices.<name>.config:

``yk8s.k8s-service-layer.rook.nodes.*.devices.<name>.config``
#############################################################



**Type:**::

  attribute set


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nodes.*.name:

``yk8s.k8s-service-layer.rook.nodes.*.name``
############################################



**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.nosds:

``yk8s.k8s-service-layer.rook.nosds``
#####################################

Number of OSDs to run. This should be equal to the number of storage meta
workers you use.


**Type:**::

  positive integer, meaning >0


**Default:**::

  3


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.operator_resources:

``yk8s.k8s-service-layer.rook.operator_resources``
##################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.operator_resources.limits.cpu:

``yk8s.k8s-service-layer.rook.operator_resources.limits.cpu``
#############################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.operator_resources.limits.memory:

``yk8s.k8s-service-layer.rook.operator_resources.limits.memory``
################################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "512Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.operator_resources.requests.cpu:

``yk8s.k8s-service-layer.rook.operator_resources.requests.cpu``
###############################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.operator_resources.requests.memory:

``yk8s.k8s-service-layer.rook.operator_resources.requests.memory``
##################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.rook.operator_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_anti_affinity:

``yk8s.k8s-service-layer.rook.osd_anti_affinity``
#################################################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_autodestroy_safe:

``yk8s.k8s-service-layer.rook.osd_autodestroy_safe``
####################################################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_resources:

``yk8s.k8s-service-layer.rook.osd_resources``
#############################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_resources.limits.cpu:

``yk8s.k8s-service-layer.rook.osd_resources.limits.cpu``
########################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_resources.limits.memory:

``yk8s.k8s-service-layer.rook.osd_resources.limits.memory``
###########################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "2Gi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_resources.requests.cpu:

``yk8s.k8s-service-layer.rook.osd_resources.requests.cpu``
##########################################################

Requests and limits for rook/ceph

The default values are the *absolute minimum* values required by rook. Going
below these numbers will make rook refuse to even create the pods. See also:
https://rook.io/docs/rook/v1.2/ceph-cluster-crd.html#cluster-wide-resources-configuration-settings


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_resources.requests.memory:

``yk8s.k8s-service-layer.rook.osd_resources.requests.memory``
#############################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.rook.osd_resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_storage_class:

``yk8s.k8s-service-layer.rook.osd_storage_class``
#################################################

Immutable when deployed. (See also :ref:`cluster-configuration.rook-configuration.updating-immutable-options`)


**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "csi-sc-cinderplugin"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.osd_volume_size:

``yk8s.k8s-service-layer.rook.osd_volume_size``
###############################################

The size of the storage backing each OSD.

Immutable when deployed. (See also :ref:`cluster-configuration.rook-configuration.updating-immutable-options`)


**Type:**::

  Kubernetes quantity


**Default:**::

  "90Gi"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools:

``yk8s.k8s-service-layer.rook.pools``
#####################################



**Type:**::

  list of (submodule)


**Default:**::

  [
    {
      name = "data";
    }
  ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools.*.create_storage_class:

``yk8s.k8s-service-layer.rook.pools.*.create_storage_class``
############################################################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools.*.device_class:

``yk8s.k8s-service-layer.rook.pools.*.device_class``
####################################################



**Type:**::

  non-empty string


**Default:**::

  "hdd"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools.*.erasure_coded:

``yk8s.k8s-service-layer.rook.pools.*.erasure_coded``
#####################################################



**Type:**::

  null or (submodule)


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools.*.erasure_coded.coding_chunks:

``yk8s.k8s-service-layer.rook.pools.*.erasure_coded.coding_chunks``
###################################################################



**Type:**::

  positive integer, meaning >0


**Default:**::

  1


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools.*.erasure_coded.data_chunks:

``yk8s.k8s-service-layer.rook.pools.*.erasure_coded.data_chunks``
#################################################################



**Type:**::

  positive integer, meaning >0


**Default:**::

  2


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools.*.failure_domain:

``yk8s.k8s-service-layer.rook.pools.*.failure_domain``
######################################################



**Type:**::

  non-empty string


**Default:**::

  "host"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools.*.name:

``yk8s.k8s-service-layer.rook.pools.*.name``
############################################



**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Example:**::

  "data"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.pools.*.replicated:

``yk8s.k8s-service-layer.rook.pools.*.replicated``
##################################################



**Type:**::

  positive integer, meaning >0


**Default:**::

  1


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.scheduling_key:

``yk8s.k8s-service-layer.rook.scheduling_key``
##############################################

Scheduling keys control where services may run. A scheduling key corresponds
to both a node label and to a taint. In order for a service to run on a node,
it needs to have that label key.
If no scheduling key is defined for a service, it will run on any untainted
node.


**Type:**::

  null or Kubernetes label


**Default:**::

  null


**Example:**::

  "${scheduling_key_prefix}/storage"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.skip_upgrade_checks:

``yk8s.k8s-service-layer.rook.skip_upgrade_checks``
###################################################

Whether to enable Rook's upgrade checks on Ceph daemons during an upgrade.

If OSDs are not replicated, the rook-ceph-operator will reject
to perform upgrades, because OSDs will become unavailable.
Set to True so rook will update even if OSDs would become unavailable.
Use this at YOUR OWN RISK, only if you know what you’re doing.
https://rook.github.io/docs/rook/v1.3/ceph-cluster-crd.html#cluster-settings
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.toolbox:

``yk8s.k8s-service-layer.rook.toolbox``
#######################################

Enable the rook toolbox, which is a pod with ceph tools installed to
introspect the cluster state.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.use_all_available_devices:

``yk8s.k8s-service-layer.rook.use_all_available_devices``
#########################################################

See :doc:`/user/guide/rook/custom-storage`


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.use_all_available_nodes:

``yk8s.k8s-service-layer.rook.use_all_available_nodes``
#######################################################

See :doc:`/user/guide/rook/custom-storage`


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.use_host_networking:

``yk8s.k8s-service-layer.rook.use_host_networking``
###################################################

Whether to enable usage of the host network..

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix


.. _configuration-options.yk8s.k8s-service-layer.rook.version:

``yk8s.k8s-service-layer.rook.version``
#######################################

Version of rook to deploy


**Type:**::

  Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "v1.16.6"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/rook.nix

