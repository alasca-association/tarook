.. _configuration-options.yk8s.kubernetes.network:

yk8s.kubernetes.network
^^^^^^^^^^^^^^^^^^^^^^^



.. _configuration-options.yk8s.kubernetes.network.bgp_announce_service_ips:

``yk8s.kubernetes.network.bgp_announce_service_ips``
####################################################

Whether to enable announcement of the service cluster IP range to external
BGP peers. By default, only per-node pod networks are announced.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.bgp_gateway_as:

``yk8s.kubernetes.network.bgp_gateway_as``
##########################################



**Type:**::

  signed integer


**Default:**::

  65000


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.bgp_worker_as:

``yk8s.kubernetes.network.bgp_worker_as``
#########################################



**Type:**::

  positive integer, meaning >0


**Default:**::

  64512


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.ipv4_nat_outgoing:

``yk8s.kubernetes.network.ipv4_nat_outgoing``
#############################################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.ipv6_nat_outgoing:

``yk8s.kubernetes.network.ipv6_nat_outgoing``
#############################################



**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.pod_subnet:

``yk8s.kubernetes.network.pod_subnet``
######################################

This is the IPv4 subnet used by Kubernetes for Pods. Subnets will be delegated
automatically to each node.


**Type:**::

  string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])/([0-9]|[12][0-9]|3[0-2])$


**Default:**::

  "10.244.0.0/16"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.pod_subnet_v6:

``yk8s.kubernetes.network.pod_subnet_v6``
#########################################

This is the IPv6 subnet used by Kubernetes for Pods. Subnets will be delegated
automatically to each node.


**Type:**::

  non-empty string


**Default:**::

  "fdff:2::/56"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.service_subnet:

``yk8s.kubernetes.network.service_subnet``
##########################################

This is the IPv4 subnet used by Kubernetes for Services.


**Type:**::

  string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])/([0-9]|[12][0-9]|3[0-2])$


**Default:**::

  "10.96.0.0/12"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.service_subnet_v6:

``yk8s.kubernetes.network.service_subnet_v6``
#############################################

This is the IPv6 subnet used by Kubernetes for Services.

The service subnet is bounded; for 128-bit addresses, the mask must be >= 108
The service cluster IP range is validated by the kube-apiserver to have at most 20 host bits
https://github.com/kubernetes/kubernetes/blob/v1.9.2/cmd/kube-apiserver/app/options/validation.go#L29-L32
https://github.com/kubernetes/kubernetes/pull/12841



**Type:**::

  non-empty string


**Default:**::

  "fdff:3::/108"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/kubernetes/network.nix

