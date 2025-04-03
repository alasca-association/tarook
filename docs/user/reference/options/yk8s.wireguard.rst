.. _configuration-options.yk8s.wireguard:

yk8s.wireguard
^^^^^^^^^^^^^^


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.enabled:

``yk8s.wireguard.endpoints.*.enabled``
######################################

Whether this endpoint is enabled on the frontend nodes.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.id:

``yk8s.wireguard.endpoints.*.id``
#################################

An ID unique to this endpoint


**Type:**::

  unsigned integer, meaning >=0, or non-empty string


**Example:**::

  0


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ip_cidr:

``yk8s.wireguard.endpoints.*.ip_cidr``
######################################

IP address range to use for WireGuard clients. Must be set to a CIDR and must
not conflict with the terraform.subnet_cidr.
Should be chosen uniquely for all clusters of a customer at the very least
so that they can use all of their clusters at the same time without having
to tear down tunnels.


**Type:**::

  string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])/([0-9]|[12][0-9]|3[0-2])$


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ip_gw:

``yk8s.wireguard.endpoints.*.ip_gw``
####################################

IP address range to use for WireGuard servers. Must be set to a CIDR and must
not conflict with the terraform.subnet_cidr.
Should be chosen uniquely for all clusters of a customer at the very least
so that they can use all of their clusters at the same time without having
to tear down tunnels.


**Type:**::

  string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])/([0-9]|[12][0-9]|3[0-2])$


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ipv6_cidr:

``yk8s.wireguard.endpoints.*.ipv6_cidr``
########################################

IP address range to use for WireGuard clients. Must be set to a CIDR and must
not conflict with the terraform.subnet_cidr.
Should be chosen uniquely for all clusters of a customer at the very least
so that they can use all of their clusters at the same time without having
to tear down tunnels.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Example:**::

  "fd01::/120"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.ipv6_gw:

``yk8s.wireguard.endpoints.*.ipv6_gw``
######################################

IP address range to use for WireGuard servers. Must be set to a CIDR and must
not conflict with the terraform.subnet_cidr.
Should be chosen uniquely for all clusters of a customer at the very least
so that they can use all of their clusters at the same time without having
to tear down tunnels.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Example:**::

  "fd01::1/120"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.endpoints.*.port:

``yk8s.wireguard.endpoints.*.port``
###################################

The port Wireguard should use on the frontend nodes


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  7777


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers:

``yk8s.wireguard.peers``
########################

The Wireguard peers that should be able to connect to the frontend nodes.


**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ident:

``yk8s.wireguard.peers.*.ident``
################################

An identifier for the public key


**Type:**::

  non-empty string


**Example:**::

  "name.lastname"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ip:

``yk8s.wireguard.peers.*.ip``
#############################



**Type:**::

  null or string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])/([0-9]|[12][0-9]|3[0-2])$ or string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ips:

``yk8s.wireguard.peers.*.ips``
##############################



**Type:**::

  attribute set of (string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])/([0-9]|[12][0-9]|3[0-2])$ or string matching the pattern ^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9]).){3}(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])$)


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ipsv6:

``yk8s.wireguard.peers.*.ipsv6``
################################



**Type:**::

  attribute set of non-empty string


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.ipv6:

``yk8s.wireguard.peers.*.ipv6``
###############################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard


.. _configuration-options.yk8s.wireguard.peers.*.pub_key:

``yk8s.wireguard.peers.*.pub_key``
##################################

The public key of the peer created with `wg keygen`


**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/wireguard

