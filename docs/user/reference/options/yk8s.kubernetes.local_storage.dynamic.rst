.. _configuration-options.yk8s.kubernetes.local_storage.dynamic:

yk8s.kubernetes.local_storage.dynamic
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



.. _configuration-options.yk8s.kubernetes.local_storage.dynamic.data_directory:

``yk8s.kubernetes.local_storage.dynamic.data_directory``
########################################################

Directory where the volumes will be placed on the worker node


**Type:**::

  Absolute POSIX path (without special '.' and '..')


**Default:**::

  "/mnt/dynamic-data"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-path-provisioner.nix


.. _configuration-options.yk8s.kubernetes.local_storage.dynamic.enabled:

``yk8s.kubernetes.local_storage.dynamic.enabled``
#################################################

Whether to enable dynamic local storage provisioning. This provides a storage class which
can be used with PVCs to allocate local storage on a node.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-path-provisioner.nix


.. _configuration-options.yk8s.kubernetes.local_storage.dynamic.namespace:

``yk8s.kubernetes.local_storage.dynamic.namespace``
###################################################

Namespace to deploy the components in


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "kube-system"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-path-provisioner.nix


.. _configuration-options.yk8s.kubernetes.local_storage.dynamic.nodeplugin_toleration:

``yk8s.kubernetes.local_storage.dynamic.nodeplugin_toleration``
###############################################################

nodeplugin toleration.
Setting this to true will cause the dynamic storage plugin
to run on all nodes (ignoring all taints). This is often desirable.


**Type:**::

  boolean


**Default:**::

  "\${config.yk8s.kubernetes.storage.nodeplugin_toleration}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-path-provisioner.nix


.. _configuration-options.yk8s.kubernetes.local_storage.dynamic.storageclass_name:

``yk8s.kubernetes.local_storage.dynamic.storageclass_name``
###########################################################

Name of the storage class to create.

NOTE: the static and dynamic provisioner must have distinct storage class
names if both are enabled!


**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "local-storage"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-path-provisioner.nix


.. _configuration-options.yk8s.kubernetes.local_storage.dynamic.version:

``yk8s.kubernetes.local_storage.dynamic.version``
#################################################

Version of the local path controller to deploy


**Type:**::

  OCI image tag


**Default:**::

  "v0.0.20"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-path-provisioner.nix

