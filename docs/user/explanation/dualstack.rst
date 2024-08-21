DualStack-Support on Kubernetes with Calico
===========================================

.. note::

   It is currently not possible to create an IPv6-only cluster
   with terraform.

   It is **not possible to upgrade** a single stack cluster to a
   dualStack cluster.

.. warning::

   Currently IPv6-based LoadBalancer services are not tested
   nor supported by ch-k8s-lbaas.
   See `#683 <https://gitlab.com/yaook/k8s/-/issues/683>`__.

.. note::

   Clusters enabling IPv6 **must** use ch-k8s-lbaas >= v0.9.0 (if it is enabled).

Motivation
----------

IPv4/IPv6 DualStack support enables the allocation of both IPv4 and IPv6
addresses to
`Pods <https://kubernetes.io/docs/concepts/workloads/pods/>`__ and
`Services <https://kubernetes.io/docs/concepts/services-networking/service/>`__.
This enables Pod off-cluster egress routing (e.g. the Internet) via
both, IPv4 and IPv6 interfaces.

Enabling DualStack-Support for managed-k8s
------------------------------------------

This section states necessary config changes to your mk8s setup to
enable DualStack-support.

Prerequisites
~~~~~~~~~~~~~

-  Kubernetes ``v1.21`` or later
-  Calico ``v3.11`` or later
-  For managed-k8s-on-OpenStack clusters:

   -  Terraform ``v0.12`` or later
   -  `ch-k8s-lbaas <https://github.com/cloudandheat/ch-k8s-lbaas>`__
      ``v0.3.3`` or later

Necessary changes in your config file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Adjust your ``config/config.toml`` to meet the following statements:

-  set ``ipv4_enabled = true`` and ``ipv6_enabled = true``

   - these variables are used across all stages
     to adjust setups and resources

-  specify ``subnet_v6_cidr``

   -  this is the IPv6 subnet that will be created via Terraform
   -  e.g.:

      -  ``subnet_v6_cidr = "fd00::/120"``

-  specify ``wg_ipv6_cidr`` as well as ``wg_ipv6_gw``

   -  this is the IPv6 CIDR for the allowed IP addresses of wireguard as
      well as the server/gateway IP address
   -  e.g.:

      -  ``wg_ipv6_cidr = "fd01::/120"``
      -  ``wg_ipv6_gw = "fd01::1/120"``

-  you have to choose calico as CNI plugin

   -  ``k8s_network_plugin = calico``

Design / Procedure considerations
---------------------------------

The following section provides an overview of assumptions, requirements
and design decisions for the DualStack support in managed-k8s.

DualStack-Support in OpenStack
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A Kubernetes cluster with DualStack support requires IPv4 and IPv6
connectivity between the cluster nodes. As we are deploying on top of
OpenStack, we need to adjust Terraform to fulfill the prerequisites.

In order for pods to be reachable from the outside world over IPv6
the cluster nodes must provide this IPv6 connectivity.
This is enabled with the dual stack support option
and rolled out on the underlying OpenStack nodes via Terraform.

`Enabling a DualStack network <https://docs.openstack.org/neutron/latest/admin/config-ipv6.html>`__
in OpenStack requires:

-  creating a subnet with the ``ip_version`` field set to ``6``
-  set attributes of ``ipv6_ra_mode`` and ``ipv6_address_mode``
-  we are using the DHCPv6 Stateful Configuration

   -  ``ipv6_ra_mode = "dhcpv6-stateful"``
   -  ``ipv6_address_mode = "dhcpv6-stateful"``

-  creating an IPv6 router interface

DualStack-Support for mk8s
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. note::

   The IPv6 addresses assigned to a Pod are unique local. Therefore,
   they are routable inside the network, but **cannot reach the Internet**.

Some information about the general DualStack support in Kubernetes:

-  Introduced with ``v1.16``, but not fully supported yet
-  The DualStack feature for the k8s control plane has been fully added
   in ``v1.21``
-  ``PodStatus.PodIPs`` can now hold multiple IP addresses
-  ``PodStatus.PodIP`` (legacy) is required to be the same as
   ``PodStatus.PodIPs[0]``
-  Calico routes IPv6 traffic from Pods over the nodes own IPv6
   connectivity
-  Please also refer to
   `Dual-stack support with kubeadm <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/dual-stack-support/>`__

`Creating a Kubernetes cluster with DualStack-Support <https://kubernetes.io/docs/concepts/services-networking/dual-stack/#enable-ipv4-ipv6-dual-stack>`__
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In managed-k8s, we do initialize the k8s cluster with the help of
`kubeadm <https://kubernetes.io/docs/reference/setup-tools/kubeadm/>`__
and the corresponding
`configuration file <https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file>`__.
Using configuration files for ``kubeadm`` is a hard requirement for the
DualStack-support, because some flags are only supported in the config
file and mixing CLI flags with the configuration file is not possible.

To configure ``kubelet`` for the DualStack support, it is necessary to
always
`pass the node-ips as a parameter <https://github.com/kubernetes/kubernetes/pull/95239#>`__.
Otherwise, ``kubelet`` will only annotate the first matching IP which is
usually the IPv4 address. The node IPs are checked in the
``check-dualstack`` role.

Currently not working
~~~~~~~~~~~~~~~~~~~~~

DualStack support for the k8s control plane
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``controlPlaneEndpoint`` either has to be *one* IP address or a
domain name. Because using a domain name would lead to the DNS
resolution overhead, we decided to let the control plane be IPv4-only
for now. However, a VIPv6 is created via Terraform and configured in
HAProxy such that it can be used to connect to the control plane.

IPv6 load-balanced services
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Currently we do not support IPv6 Single Stack load-balanced services
because it is unclear how exactly we want to design the IPv6 setup.

Adjust the Calico CNI for DualStack-Support
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

It is necessary to adjust the
`CNI config <https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/>`__
so that Calico’s IPAM will allocate both IPv4 and IPv6 addresses for
each new Pod.

.. code:: json

   "ipam": {
      "type": "calico-ipam",
      "assign_ipv4": "true",
      "assign_ipv6": "true"
   }

The environment variables for
`calico/node <https://docs.projectcalico.org/reference/node/configuration>`__
have to be adjusted:

-  ``IP6=autodetect``

   -  Calico will detect the
      node’s IPv6 address and use this in its BGP IPv6 config

-  ``FELIX_IPV6SUPPORT=true``

   -  so that Felix knows to program routing and
      iptables for IPv6 as well as for IPv4

DualStack-Support and Wireguard
-------------------------------

The wireguard role has been extended to create an export filter for
bird. The BGP instances using this export filter will propagate a route
to the wireguard subnet. The k8s-bgp role has been adjusted so that only
the gateway with the VIPs will peer with the k8s nodes. This is
necessary, because otherwise when trying to connect to a node over IPv6,
the node does not know a route back out of cluster.

The BGP setup has been adjusted so that the k8s nodes peer with the
currently LB-master gateway. All k8s nodes need to peer with the
LB-master gateway, because calico/node will not forward infrastructure
routes to peers. If the LB-master gateway dies, the next LB-master
automatically connects to the k8s nodes. This way, the k8s nodes know
the correct route to the currently active gateway.

.. note::

   All gateways think they have a route to the wireguard subnet,
   but only the current LB-master has.
   It is **not possible** to ssh to the secondary gateways **directly**
   using the private IP addresses.
   You can still connect to the secondary gateways using their
   public (floating) IP addresses or by using the currently active
   gateway as jumphost.
