.. _configuration-options.yk8s.load-balancing:

yk8s.load-balancing
^^^^^^^^^^^^^^^^^^^


By default, if you’re deploying on top of OpenStack, the self-developed
load-balancing solution :doc:`ch-k8s-lbaas </user/explanation/services/ch-k8s-lbaas>`
will be used to avoid the aches of using OpenStack Octavia. Nonetheless,
you are not forced to use it and can easily disable it.

The following section contains legacy load-balancing options which will
probably be removed in the foreseeable future.

.. _configuration-options.yk8s.load-balancing.deprecated_nodeport_lb_test_port:

``yk8s.load-balancing.deprecated_nodeport_lb_test_port``
########################################################



**Type:**::

  null or 16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/load-balancing.nix


.. _configuration-options.yk8s.load-balancing.haproxy_frontend_k8s_api_maxconn:

``yk8s.load-balancing.haproxy_frontend_k8s_api_maxconn``
########################################################



**Type:**::

  positive integer, meaning >0


**Default:**::

  2000


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/load-balancing.nix


.. _configuration-options.yk8s.load-balancing.haproxy_frontend_nodeport_maxconn:

``yk8s.load-balancing.haproxy_frontend_nodeport_maxconn``
#########################################################



**Type:**::

  positive integer, meaning >0


**Default:**::

  2000


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/load-balancing.nix


.. _configuration-options.yk8s.load-balancing.haproxy_stats_port:

``yk8s.load-balancing.haproxy_stats_port``
##########################################

Port for HAProxy statistics


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  48981


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/load-balancing.nix


.. _configuration-options.yk8s.load-balancing.lb_ports:

``yk8s.load-balancing.lb_ports``
################################

lb_ports is a list of ports that are exposed by HAProxy on the gateway nodes and forwarded
to NodePorts in the k8s cluster. This poor man's load-balancing / exposing of services
has been superseded by ch-k8s-lbaas. For legacy reasons and because it's useful under
certain circumstances it is kept inside the repository.
The NodePorts are either literally exposed by HAProxy or can be mapped to other ports.


**Type:**::

  list of (16 bit unsigned integer; between 0 and 65535 (both inclusive) or (submodule))


**Default:**::

  [ ]


**Example:**::

  ''
    Short form: [30060];
    Explicit form: [{external=80,nodeport=30080, layer=tcp, use_proxy_protocol=true}]
  ''


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/load-balancing.nix


.. _configuration-options.yk8s.load-balancing.openstack_lbaas:

``yk8s.load-balancing.openstack_lbaas``
#######################################

Whether to enable OpenStack-based load-balancing.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/load-balancing.nix


.. _configuration-options.yk8s.load-balancing.vrrp_priorities:

``yk8s.load-balancing.vrrp_priorities``
#######################################

A list of priorities to assign to the gateway/frontend nodes. The priorities
will be assigned based on the sorted list of matching nodes.

If more nodes exist than there are entries in this list, the rollout will
fail.

Please note the keepalived.conf manpage for choosing priority values.


**Type:**::

  list of signed integer


**Default:**::

  [
    150
    100
    50
  ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/load-balancing.nix

