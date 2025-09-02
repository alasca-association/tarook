.. _configuration-options.yk8s.infra:

yk8s.infra
^^^^^^^^^^


This section contains various configuration options necessary for all
cluster types, Terraform and bare-metal based.

.. _configuration-options.yk8s.infra.cluster_name:

``yk8s.infra.cluster_name``
###########################

Name of the cluster that is to be build and managed.

Used to distinguish the cluster from others
and to name harbour infrastructure resources.


**Type:**::

  non-empty string without spaces


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.hosts_file:

``yk8s.infra.hosts_file``
#########################

A custom hosts file in case :ref:`configuration-options.yk8s.openstack.enabled` is set to ``false``


**Type:**::

  null or path in the Nix store


**Default:**::

  null


**Example:**::

  ./hosts


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ipv4_enabled:

``yk8s.infra.ipv4_enabled``
###########################

Whether to enable IPv4.

**Type:**::

  boolean


**Default:**::

  true


**Example:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ipv6_enabled:

``yk8s.infra.ipv6_enabled``
###########################

Whether to enable IPv6.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.networking_fixed_ip:

``yk8s.infra.networking_fixed_ip``
##################################



**Type:**::

  null or IPv4 address in four-octets decimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.networking_fixed_ip_v6:

``yk8s.infra.networking_fixed_ip_v6``
#####################################



**Type:**::

  null or IPv6 address in colon-hexadecimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.subnet_cidr:

``yk8s.infra.subnet_cidr``
##########################

The IPv4 CIDR of the internally used network.
Only applies if :ref:`configuration-options.yk8s.infra.ipv4_enabled` is set to ``true``.


**Type:**::

  IPv4 address in four-octets decimal notation plus subnet in CIDR notation


**Default:**::

  "172.30.154.0/24"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.subnet_v6_cidr:

``yk8s.infra.subnet_v6_cidr``
#############################

The IPv6 CIDR of the internally used network.
Only applies if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is set to ``true``.


**Type:**::

  IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation


**Default:**::

  "fd00::/120"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix

