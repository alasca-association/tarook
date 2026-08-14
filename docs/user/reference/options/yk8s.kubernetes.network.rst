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
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.bgp_gateway_as:

``yk8s.kubernetes.network.bgp_gateway_as``
##########################################



**Type:**::

  Autonomous system number reserved for private use
  
  Allowed ranges: 64512-65534, 4200000000-4294967294


**Default:**::

  65000


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.bgp_worker_as:

``yk8s.kubernetes.network.bgp_worker_as``
#########################################



**Type:**::

  Autonomous system number reserved for private use
  
  Allowed ranges: 64512-65534, 4200000000-4294967294


**Default:**::

  64512


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.ipv4_nat_outgoing:

``yk8s.kubernetes.network.ipv4_nat_outgoing``
#############################################

Enable outgoing IPv4 network address translation


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.ipv6_nat_outgoing:

``yk8s.kubernetes.network.ipv6_nat_outgoing``
#############################################

Enable outgoing IPv6 network address translation


**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.kube_proxy.enabled:

``yk8s.kubernetes.network.kube_proxy.enabled``
##############################################

Whether to enable kube-proxy. Disable if you want to use a eBPF dataplane
.

**Type:**::

  boolean


**Default:**::

  true


**Example:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.kube_proxy.kubeProxyConfiguration:

``yk8s.kubernetes.network.kube_proxy.kubeProxyConfiguration``
#############################################################



**Type:**::

  attribute set containing JSON compatible values


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.kube_proxy.mode:

``yk8s.kubernetes.network.kube_proxy.mode``
###########################################

Which proxy mode to use. Note that ``ipvs`` mode is deprecated.


**Type:**::

  one of "iptables", "nftables", "ipvs"


**Default:**::

  if config.yk8s.infra.ipv6_enabled then "ipvs" else "iptables"
  


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.pod_subnet:

``yk8s.kubernetes.network.pod_subnet``
######################################

This is the IPv4 subnet used by Kubernetes for Pods. Subnets will be delegated
automatically to each node.


**Type:**::

  IPv4 address in four-octets decimal notation plus subnet in CIDR notation


**Default:**::

  "10.244.0.0/16"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.pod_subnet_v6:

``yk8s.kubernetes.network.pod_subnet_v6``
#########################################

This is the IPv6 subnet used by Kubernetes for Pods. Subnets will be delegated
automatically to each node.


**Type:**::

  IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation


**Default:**::

  "fdff:2::/56"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.service_subnet:

``yk8s.kubernetes.network.service_subnet``
##########################################

This is the IPv4 subnet used by Kubernetes for Services.


**Type:**::

  IPv4 address in four-octets decimal notation plus subnet in CIDR notation


**Default:**::

  "10.96.0.0/12"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.service_subnet_v6:

``yk8s.kubernetes.network.service_subnet_v6``
#############################################

This is the IPv6 subnet used by Kubernetes for Services.

The service subnet is bounded; for 128-bit addresses, the mask must be >= 108
The service cluster IP range is validated by the kube-apiserver to have at most 20 host bits
https://github.com/kubernetes/kubernetes/blob/v1.9.2/cmd/kube-apiserver/app/options/validation.go#L29-L32
https://github.com/kubernetes/kubernetes/pull/12841



**Type:**::

  IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation


**Default:**::

  "fdff:3::/108"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix

