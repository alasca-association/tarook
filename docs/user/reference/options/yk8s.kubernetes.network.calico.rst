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

  IPv4 address in four-octets decimal notation


**Default:**::

  "244.0.0.1"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


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
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


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
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.chart_ref:

``yk8s.kubernetes.network.calico.helm.chart_ref``
#################################################

The chart reference (relative to the repository) of the Calico Helm chart.


**Type:**::

  RFC3986 relative URL path


**Default:**::

  "tigera-operator"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.chart_repo_url:

``yk8s.kubernetes.network.calico.helm.chart_repo_url``
######################################################

The URL to the Helm repository for the Calico Helm chart.


**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://docs.tigera.io/calico/charts"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.chart_version:

``yk8s.kubernetes.network.calico.helm.chart_version``
#####################################################

Version of the Calico Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "3.31.5"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.release_name:

``yk8s.kubernetes.network.calico.helm.release_name``
####################################################

The release name inside the cluster for Calico.


**Type:**::

  non-empty string


**Default:**::

  "calico"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.release_namespace:

``yk8s.kubernetes.network.calico.helm.release_namespace``
#########################################################

The namespace in which to install Calico.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "tigera-operator"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.values:

``yk8s.kubernetes.network.calico.helm.values``
##############################################

Helm values for the Calico helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://github.com/projectcalico/calico/blob/master/charts/tigera-operator/values.yaml


**Type:**::

  open submodule of (attribute set containing JSON compatible values)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.values.installation.calicoNetwork.mtu:

``yk8s.kubernetes.network.calico.helm.values.installation.calicoNetwork.mtu``
#############################################################################



**Type:**::

  positive integer, meaning >0


**Default:**::

  "\${if config.yk8s.openstack.enabled then config.yk8s.openstack.network_mtu else 1500}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.values.installation.controlPlaneReplicas:

``yk8s.kubernetes.network.calico.helm.values.installation.controlPlaneReplicas``
################################################################################



**Type:**::

  unspecified value


**Default:**::

  "automatic"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.helm.values.installation.registry:

``yk8s.kubernetes.network.calico.helm.values.installation.registry``
####################################################################

Specify the registry endpoint
Changing this value can be useful if one endpoint hosts outdated images or you're subject to rate limiting


**Type:**::

  RFC1123 subdomain name


**Default:**::

  "quay.io"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


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
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix


.. _configuration-options.yk8s.kubernetes.network.calico.values_file_path:

``yk8s.kubernetes.network.calico.values_file_path``
###################################################

.. note:: DEPRECATED

   This option is going to be removed.
   Please use :ref:`configuration-options.yk8s.kubernetes.network.calico.helm.values` instead.

For the operator-based installation,
it is possible to link to self-maintained values file for the helm chart



**Type:**::

  path in the Nix store


**Default:**::

  "Values given in :ref:`configuration-options.yk8s.kubernetes.network.calico.helm.values`"


**Example:**::

  ./calico/helm/values.yaml


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/calico.nix

