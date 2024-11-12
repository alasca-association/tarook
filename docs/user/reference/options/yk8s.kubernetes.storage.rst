.. _configuration-options.yk8s.kubernetes.storage:

yk8s.kubernetes.storage
^^^^^^^^^^^^^^^^^^^^^^^



.. _configuration-options.yk8s.kubernetes.storage.cinder_enable_topology:

``yk8s.kubernetes.storage.cinder_enable_topology``
##################################################

This flag enables the topology feature gate of the cinder controller plugin.
Its purpose is to allocate volumes from cinder which are in the same AZ as
the worker node to which the volume should be attached.
Important: Cinder must support AZs and the AZs must match the AZs used by nova!


**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/storage.nix


.. _configuration-options.yk8s.kubernetes.storage.nodeplugin_toleration:

``yk8s.kubernetes.storage.nodeplugin_toleration``
#################################################

Whether to enable nodeplugin toleration.
Setting this to true will cause the storage plugins
to run on all nodes (ignoring all taints). This is often desirable.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/storage.nix


.. _configuration-options.yk8s.kubernetes.storage.rook_enabled:

``yk8s.kubernetes.storage.rook_enabled``
########################################

Whether to enable Rook.
Many clusters will want to use rook, so you should enable
or disable it here if you want. It requires extra options
which need to be chosen with care.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/storage.nix
