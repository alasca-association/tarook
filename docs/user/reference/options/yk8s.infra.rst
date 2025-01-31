.. _configuration-options.yk8s.infra:

yk8s.infra
^^^^^^^^^^


.. _cluster-configuration.infra-configuration:

Infra Configuration
^^^^^^^^^^^^^^^^^^^

This section contains various configuration options necessary for all
cluster types, Terraform and bare-metal based.

.. _configuration-options.yk8s.infra.cluster_name:

``yk8s.infra.cluster_name``
###########################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.hosts_file:

``yk8s.infra.hosts_file``
#########################

A custom hosts file in case openstack is disabled


**Type:**::

  null or path in the Nix store


**Default:**::

  null


**Example:**::

  "./hosts"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ipv4_enabled:

``yk8s.infra.ipv4_enabled``
###########################

If set to true, ipv4 will be used


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ipv6_enabled:

``yk8s.infra.ipv6_enabled``
###########################

If set to true, ipv6 will be used


**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.subnet_cidr:

``yk8s.infra.subnet_cidr``
##########################



**Type:**::

  non-empty string


**Default:**::

  "172.30.154.0/24"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.subnet_v6_cidr:

``yk8s.infra.subnet_v6_cidr``
#############################



**Type:**::

  non-empty string


**Default:**::

  "fd00::/120"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/infra.nix

