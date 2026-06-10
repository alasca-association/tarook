.. _configuration-options.yk8s.ipsec:

yk8s.ipsec
^^^^^^^^^^


More details about the IPsec setup can be found
:doc:`here </user/explanation/vpn/ipsec>`.

.. _configuration-options.yk8s.ipsec.enabled:

``yk8s.ipsec.enabled``
######################

Whether to enable IPsec.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.esp_proposals:

``yk8s.ipsec.esp_proposals``
############################

A list of parent SA proposals to offer to the client.


**Type:**::

  list of IPsec proposal string


**Default:**::

  config.yk8s.ipsec.proposals


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.local_networks:

``yk8s.ipsec.local_networks``
#############################

List of CIDRs to offer to the peer


**Type:**::

  list of (IPv4 address in four-octets decimal notation plus subnet in CIDR notation or IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation)


**Default:**::

  [
    "172.30.154.0/24"
  ]


**Example:**::

  ''
    Set the following for a working NAT-free setup
    [
      config.yk8s.infra.subnet_cidr
      config.yk8s.kubernetes.network.pod_subnet
      config.yk8s.kubernetes.network.service_subnet
    ]
  ''


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.peer_networks:

``yk8s.ipsec.peer_networks``
############################

List of CIDRs to route to the peer. If not set, only dynamic IP
assignments will be routed.


**Type:**::

  list of (IPv4 address in four-octets decimal notation plus subnet in CIDR notation or IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.proposals:

``yk8s.ipsec.proposals``
########################

A list of parent SA proposals to offer to the client.


**Type:**::

  list of IPsec proposal string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.purge_installation:

``yk8s.ipsec.purge_installation``
#################################

Whether to enable purging the IPsec installation.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.remote_addrs:

``yk8s.ipsec.remote_addrs``
###########################

List of addresses to accept as remote. When initiating, the first single IP
address is used.


**Type:**::

  list of (IPv4 address in four-octets decimal notation or IPv6 address in colon-hexadecimal notation)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.remote_name:

``yk8s.ipsec.remote_name``
##########################



**Type:**::

  non-empty string


**Default:**::

  "peerid"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.remote_private_addrs:

``yk8s.ipsec.remote_private_addrs``
###################################

Private address of remote endpoints.
only used when :ref:`configuration-options.yk8s.ipsec.test_enabled` is ``true``


**Type:**::

  null or (list of (IPv4 address in four-octets decimal notation or IPv6 address in colon-hexadecimal notation))


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.test_enabled:

``yk8s.ipsec.test_enabled``
###########################

Whether to enable the test suite.
Must make sure a remote endpoint, with ipsec enabled, is running and open for connections.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix


.. _configuration-options.yk8s.ipsec.virtual_subnet_pool:

``yk8s.ipsec.virtual_subnet_pool``
##################################

Pool to source virtual IP addresses from. Those are the IP addresses assigned
to clients which do not have remote networks. (e.g.: "10.3.0.0/24")


**Type:**::

  null or (list of (IPv4 address in four-octets decimal notation plus subnet in CIDR notation or IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation))


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ipsec.nix

