.. _configuration-options.yk8s.kubernetes.network.calico:

yk8s.kubernetes.network.calico
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


The following configuration options are specific to calico, our CNI
plugin in use.

.. _configuration-options.yk8s.kubernetes.network.calico.bgp_router_id:

``yk8s.kubernetes.network.calico.bgp_router_id``
################################################

An arbitrary ID (four octet unsigned integer) used by Calico as BGP Identifier


**Type:**::

  string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])$


**Default:**::

  "244.0.0.1"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.custom_version:

``yk8s.kubernetes.network.calico.custom_version``
#################################################

We're mapping a fitting calico version to the configured Kubernetes version.
You can however pick a custom Calico version.
Be aware that not all combinations of Kubernetes and Calico versions are recommended:
https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements
Any version should work as long as
you stick to the calico-Kubernetes compatibility matrix.

If not specified here, a predefined Calico version will be matched against
the above specified Kubernetes version.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Example:**::

  "3.25.1"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.enabled:

``yk8s.kubernetes.network.calico.enabled``
##########################################

Whether to enable Calico, a high-performance, pure IP networking, policy engine. Calico provides
layer 3 networking capabilities and associates a virtual router with each node.
Allows the establishment of zone boundaries through BGP


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.encapsulation:

``yk8s.kubernetes.network.calico.encapsulation``
################################################

EncapsulationType is the type of encapsulation to use on an IP pool.
Only takes effect for operator-based installations
https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.EncapsulationType


**Type:**::

  one of "IPIP", "VXLAN", "IPIPCrossSubnet", "VXLANCrossSubnet", "None"


**Default:**::

  "None"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.image_registry:

``yk8s.kubernetes.network.calico.image_registry``
#################################################

Specify the registry endpoint
Changing this value can be useful if one endpoint hosts outdated images or you're subject to rate limiting


**Type:**::

  non-empty string


**Default:**::

  "quay.io"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.ipipmode:

``yk8s.kubernetes.network.calico.ipipmode``
###########################################

Only takes effect for manifest-based installations
Define if the IP-in-IP encapsulation of calico should be activated
https://docs.tigera.io/calico/latest/reference/resources/ippool#spec


**Type:**::

  one of "Always", "CrossSubnet", "Never"


**Default:**::

  "Never"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.mtu:

``yk8s.kubernetes.network.calico.mtu``
######################################



**Type:**::

  signed integer


**Default:**::

  "\${if config.yk8s.openstack.enabled then config.yk8s.openstack.network_mtu else 1500}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.values_file_path:

``yk8s.kubernetes.network.calico.values_file_path``
###################################################

For the operator-based installation,
it is possible to link to self-maintained values file for the helm chart


**Type:**::

  null or non-empty string


**Default:**::

  null


**Example:**::

  "path-to-a-custom/values.yaml"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix

