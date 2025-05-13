.. _configuration-options.yk8s.kubernetes.kubelet:

yk8s.kubernetes.kubelet
^^^^^^^^^^^^^^^^^^^^^^^


The LCM supports the customization of certain variables of ``kubelet``
for (meta-)worker nodes.

.. note::

  Applying changes requires to enable
  :ref:`disruptive actions <environmental-variables.behavior-altering-variables>`.

.. _configuration-options.yk8s.kubernetes.kubelet.evictionhard_nodefs_available:

``yk8s.kubernetes.kubelet.evictionhard_nodefs_available``
#########################################################

Config for hard eviction values.
Note: To change this value you have to release the Kraken


**Type:**::

  Kubernetes threshold


**Default:**::

  "10%"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/kubelet.nix


.. _configuration-options.yk8s.kubernetes.kubelet.evictionhard_nodefs_inodesfree:

``yk8s.kubernetes.kubelet.evictionhard_nodefs_inodesfree``
##########################################################

Config for hard eviction values.
Note: To change this value you have to release the Kraken


**Type:**::

  Kubernetes threshold


**Default:**::

  "5%"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/kubelet.nix


.. _configuration-options.yk8s.kubernetes.kubelet.evictionsoft_memory_period:

``yk8s.kubernetes.kubelet.evictionsoft_memory_period``
######################################################

Config for soft eviction values.
Note: To change this value you have to release the Kraken


**Type:**::

  Kubernetes duration string


**Default:**::

  "1m30s"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/kubelet.nix


.. _configuration-options.yk8s.kubernetes.kubelet.pod_limit_master:

``yk8s.kubernetes.kubelet.pod_limit_master``
############################################

Maximum number of Pods per master node
Increasing this value may also decrease performance,
as more Pods can be packed into a single node.
Therefore it's especially helpful for nodes which have much resources.


**Type:**::

  signed integer


**Default:**::

  110


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/kubelet.nix


.. _configuration-options.yk8s.kubernetes.kubelet.pod_limit_worker:

``yk8s.kubernetes.kubelet.pod_limit_worker``
############################################

Maximum number of Pods per worker node
Increasing this value may also decrease performance,
as more Pods can be packed into a single node.
Therefore it's especially helpful for nodes which have much resources.


**Type:**::

  unsigned integer, meaning >=0


**Default:**::

  110


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/kubelet.nix

