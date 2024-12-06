.. _configuration-options.yk8s.kubernetes.local_storage.static:

yk8s.kubernetes.local_storage.static
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



.. _configuration-options.yk8s.kubernetes.local_storage.static.data_directory:

``yk8s.kubernetes.local_storage.static.data_directory``
#######################################################



**Type:**::

  Absolute POSIX path (without special '.' and '..')


**Default:**::

  "/mnt/data"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-storage-controller.nix


.. _configuration-options.yk8s.kubernetes.local_storage.static.discovery_directory:

``yk8s.kubernetes.local_storage.static.discovery_directory``
############################################################



**Type:**::

  Absolute POSIX path (without special '.' and '..')


**Default:**::

  "/mnt/mk8s-disks"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-storage-controller.nix


.. _configuration-options.yk8s.kubernetes.local_storage.static.enabled:

``yk8s.kubernetes.local_storage.static.enabled``
################################################

Whether to enable static provisioning of local storage. This provisions a single local
storage volume per worker node.

It is recommended to use the dynamic local storage instead.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-storage-controller.nix


.. _configuration-options.yk8s.kubernetes.local_storage.static.namespace:

``yk8s.kubernetes.local_storage.static.namespace``
##################################################



**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "kube-system"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-storage-controller.nix


.. _configuration-options.yk8s.kubernetes.local_storage.static.nodeplugin_toleration:

``yk8s.kubernetes.local_storage.static.nodeplugin_toleration``
##############################################################



**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-storage-controller.nix


.. _configuration-options.yk8s.kubernetes.local_storage.static.storageclass_name:

``yk8s.kubernetes.local_storage.static.storageclass_name``
##########################################################

Name of the storage class to create.

NOTE: the static and dynamic provisioner must have distinct storage class
names if both are enabled!


**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "local-storage"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-storage-controller.nix


.. _configuration-options.yk8s.kubernetes.local_storage.static.version:

``yk8s.kubernetes.local_storage.static.version``
################################################

See https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/releases/tag/v2.5.0


**Type:**::

  OCI image tag


**Default:**::

  "v2.5.0"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/k8s-local-storage-controller.nix

