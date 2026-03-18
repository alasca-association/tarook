.. _configuration-options.yk8s.wireguard:

yk8s.wireguard
^^^^^^^^^^^^^^


.. note:: Wireguard is currently only supported on gateway nodes.

You **MUST** add yourself to the :doc:`wireguard </user/explanation/vpn/wireguard>`
peers.

You can do so either in the following section of the config file or by
using and configuring a git submodule. This submodule would then refer
to another repository, holding the wireguard public keys of everybody
that should have access to the cluster by default. This is the
recommended approach for companies and organizations.

.. _configuration-options.yk8s.wireguard.enabled:

``yk8s.wireguard.enabled``
##########################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoint_defaults.ip:

``yk8s.wireguard.endpoint_defaults.ip``
#######################################

IPv4 address of the Wireguard endpoint on a gateway node.

For a high-available gateway plane
this IPv4 address should be managed by a load-balancer solution.


**Type:**::

  null or IPv4 address in four-octets decimal notation


**Default:**::

  if :ref:`configuration-options.yk8s.terraform.enabled`
  then *<floating IPv4 address associated with the VRRP port>*
  else ``null``
  


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints:

``yk8s.wireguard.endpoints``
############################

Defines a WireGuard endpoint/server.
To allow rolling key rotations, multiple endpoints can be added.
Each endpoint's id, port and subnet need to be unique.


**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.enabled:

``yk8s.wireguard.endpoints.*.enabled``
######################################

Whether this endpoint is enabled on the frontend nodes.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.id:

``yk8s.wireguard.endpoints.*.id``
#################################

An ID unique to this endpoint


**Type:**::

  unsigned integer, meaning >=0


**Example:**::

  0


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ip:

``yk8s.wireguard.endpoints.*.ip``
#################################

IPv4 address of the Wireguard endpoint on a gateway node.

For a high-available gateway plane
this IPv4 address should be managed by a load-balancer solution.


**Type:**::

  null or IPv4 address in four-octets decimal notation


**Default:**::

  :ref:`configuration-options.yk8s.wireguard.endpoint_defaults.ip`


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ip_cidr:

``yk8s.wireguard.endpoints.*.ip_cidr``
######################################

IP address range to use for WireGuard clients. Must be set to a CIDR and must
not conflict with the :ref:`configuration-options.yk8s.infra.subnet_cidr`.
Should be chosen uniquely for all clusters of a customer at the very least
so that they can use all of their clusters at the same time without having
to tear down tunnels.


**Type:**::

  IPv4 address in four-octets decimal notation plus subnet in CIDR notation


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ip_gw:

``yk8s.wireguard.endpoints.*.ip_gw``
####################################

IP address range to use for WireGuard servers. Must be set to a CIDR and must
not conflict with the :ref:`configuration-options.yk8s.infra.subnet_cidr`.
Should be chosen uniquely for all clusters of a customer at the very least
so that they can use all of their clusters at the same time without having
to tear down tunnels.


**Type:**::

  IPv4 address in four-octets decimal notation plus subnet in CIDR notation


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ipv6_cidr:

``yk8s.wireguard.endpoints.*.ipv6_cidr``
########################################

IP address range to use for WireGuard clients. Must be set to a CIDR and must
not conflict with the :ref:`configuration-options.yk8s.infra.subnet_cidr`.
Should be chosen uniquely for all clusters of a customer at the very least
so that they can use all of their clusters at the same time without having
to tear down tunnels.


**Type:**::

  null or IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation


**Default:**::

  null


**Example:**::

  "fd01::/120"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ipv6_gw:

``yk8s.wireguard.endpoints.*.ipv6_gw``
######################################

IP address range to use for WireGuard servers. Must be set to a CIDR and must
not conflict with the :ref:`configuration-options.yk8s.infra.subnet_cidr`.
Should be chosen uniquely for all clusters of a customer at the very least
so that they can use all of their clusters at the same time without having
to tear down tunnels.


**Type:**::

  null or IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation


**Default:**::

  null


**Example:**::

  "fd01::1/120"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.port:

``yk8s.wireguard.endpoints.*.port``
###################################

The port Wireguard should use on the frontend nodes


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  7777


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers:

``yk8s.wireguard.peers``
########################

The Wireguard peers that should be able to connect to the frontend nodes.

The orchestrator must be included in this list.


**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Example:**::

  [
    {
      ident = "alice";
      pub_key = "ExampleWgKeyLiKUsKjhSDY9u06pX68rbdg4V6dkHFo=";
    }
    {
      ident = "bob";
      pub_key = "AnotherExampleWgKey8xOMMOW2dsda6s6BKkasi3al=";
    }
  ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ident:

``yk8s.wireguard.peers.*.ident``
################################

An identifier for the public key


**Type:**::

  POSIX file name


**Example:**::

  "name.lastname"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ip:

``yk8s.wireguard.peers.*.ip``
#############################



**Type:**::

  null or IPv4 address in four-octets decimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ips:

``yk8s.wireguard.peers.*.ips``
##############################



**Type:**::

  attribute set of (IPv4 address in four-octets decimal notation plus subnet in CIDR notation or IPv4 address in four-octets decimal notation)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ipsv6:

``yk8s.wireguard.peers.*.ipsv6``
################################



**Type:**::

  attribute set of (IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation or IPv6 address in colon-hexadecimal notation)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ipv6:

``yk8s.wireguard.peers.*.ipv6``
###############################



**Type:**::

  null or IPv6 address in colon-hexadecimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.pub_key:

``yk8s.wireguard.peers.*.pub_key``
##################################

The public key of the peer created with `wg keygen`


**Type:**::

  Wireguard key


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/wireguard

