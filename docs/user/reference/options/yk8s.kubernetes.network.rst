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

  true


**Example:**::

  false


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

Whether to enable kube-proxy.

.. warning::

   kube-proxy interferes with Calico running in eBPF dataplane mode, which is the default.
   Enable with care.

.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.kube_proxy.extraKubeProxyConfiguration:

``yk8s.kubernetes.network.kube_proxy.extraKubeProxyConfiguration``
##################################################################

Extra settings for the ``KubeProxyConfiguration``, see the
`kube-proxy Configuration (v1alpha1) <https://kubernetes.io/docs/reference/config-api/kube-proxy-config.v1alpha1/>`_.

The settings are merged into the configuration that Tarook generates and take precedence.
Lists are appended.
The proxy mode is set via :ref:`configuration-options.yk8s.kubernetes.network.kube_proxy.mode`.

Changes are applied to existing clusters and kube-proxy is restarted.
Fields that are removed here keep their value in the cluster.

To see the rendered configuration, look at the file referenced by
``k8s_network_kube_proxy_kubeProxyConfigurationFile`` in
``inventory/yaook-k8s/group_vars/all/kubernetes.yaml``
(updated by :ref:`update-inventory.sh <actions-references.update-inventorysh>`).
The configuration of an existing cluster is stored in the ``kube-system/kube-proxy`` ConfigMap.


**Type:**::

  attribute set of (attribute set containing JSON compatible values)


**Default:**::

  { }


**Example:**::

  {
    conntrack = {
      maxPerCore = 65536;
    };
  }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/network.nix


.. _configuration-options.yk8s.kubernetes.network.kube_proxy.mode:

``yk8s.kubernetes.network.kube_proxy.mode``
###########################################

Which proxy mode to use. Note that ``ipvs`` mode is deprecated.

It is only applied when the cluster is created.
If it differs from the mode kube-proxy runs in, applying the configuration fails.
To switch the mode of an existing cluster, change ``mode`` in the ``kube-system/kube-proxy`` ConfigMap,
restart kube-proxy (``kubectl -n kube-system rollout restart daemonset kube-proxy``)
and set this option accordingly.
When switching to or from ``nftables``, Calico's dataplane has to be switched as well.
When switching between ``iptables`` and ``ipvs``, the rules of the previous mode stay on the nodes
until they are removed, e.g. by rebooting the nodes one after another.


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

