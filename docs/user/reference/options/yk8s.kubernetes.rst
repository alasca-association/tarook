.. _configuration-options.yk8s.kubernetes:

yk8s.kubernetes
^^^^^^^^^^^^^^^


This section contains generic information about the Kubernetes cluster
configuration.

.. _configuration-options.yk8s.kubernetes.apiserver.frontend_port:

``yk8s.kubernetes.apiserver.frontend_port``
###########################################



**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  8888


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.apiserver.memory_limit:

``yk8s.kubernetes.apiserver.memory_limit``
##########################################

Memory resources limit for the apiserver


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Example:**::

  "1Gi"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.controller_manager.enable_signing_requests:

``yk8s.kubernetes.controller_manager.enable_signing_requests``
##############################################################

Whether to enable signing requests.

Note: This currently means that the cluster CA key is copied to the control
plane nodes which decreases security compared to storing the CA only in the Vault.
IMPORTANT: Manual steps required when enabled after cluster creation
The CA key is made available through Vault's kv store and fetched by Ansible.
Due to Vault's security architecture this means
you must run the CA rotation script
(or manually upload the CA key from your backup to Vault's kv store).
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.controller_manager.large_cluster_size_threshold:

``yk8s.kubernetes.controller_manager.large_cluster_size_threshold``
###################################################################



**Type:**::

  signed integer


**Default:**::

  50


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.is_gpu_cluster:

``yk8s.kubernetes.is_gpu_cluster``
##################################

Set this variable if this cluster contains worker with GPU access
and you want to make use of these inside of the cluster,
so that the driver and surrounding framework is deployed.


**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.monitoring.enabled:

``yk8s.kubernetes.monitoring.enabled``
######################################

Whether to enable Prometheus-based monitoring.
For prometheus-specific configurations take a look at the config options in
:ref:`configuration-options.yk8s.k8s-service-layer.prometheus`.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/monitoring.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.version:

``yk8s.kubernetes.version``
###########################

Kubernetes version


**Type:**::

  string matching the pattern ^1.(29|30|31).[0-9]+$


**Default:**::

  "1.31.5"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.virtualize_gpu:

``yk8s.kubernetes.virtualize_gpu``
##################################

Set this variable to virtualize Nvidia GPUs on worker nodes
for usage outside of the Kubernetes cluster / above the Kubernetes layer.
It will install a VGPU manager on the worker node and
split the GPU according to chosen vgpu type.
Note: This will not install Nvidia drivers to utilize vGPU guest VMs!!
If set to true, please set further variables in :ref:`configuration-options.yk8s.miscellaneous`.
Note: This is mutually exclusive with :ref:`configuration-options.yk8s.kubernetes.is_gpu_cluster`.


**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes

