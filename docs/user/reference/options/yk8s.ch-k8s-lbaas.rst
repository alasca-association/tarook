.. _configuration-options.yk8s.ch-k8s-lbaas:

yk8s.ch-k8s-lbaas
^^^^^^^^^^^^^^^^^


``ch-k8s-lbaas`` is a LoadBalancing-solution for clusters running on OpenStack
as well as clusters running on bare metal.
Further information about it can be found here: :doc:`/user/explanation/services/ch-k8s-lbaas`.

.. _configuration-options.yk8s.ch-k8s-lbaas.agent_port:

``yk8s.ch-k8s-lbaas.agent_port``
################################

The TCP port on which the LBaaS agent should listen on the frontend nodes.


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  15203


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.agent_source:

``yk8s.ch-k8s-lbaas.agent_source``
##################################



**Type:**::

  RFC3986 HTTP(S) URL (scheme, authority and path only)


**Default:**::

  "https://github.com/cloudandheat/ch-k8s-lbaas/releases/download"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.agent_urls:

``yk8s.ch-k8s-lbaas.agent_urls``
################################

Customize URLs for the agents. This will typically be a list of HTTP URLs
like http://agent_ip:15203. This option must be set if :ref:`configuration-options.yk8s.ch-k8s-lbaas.port_manager` is
set to ``static`` and is ignored otherwise.


**Type:**::

  list of RFC3986 HTTP URL (scheme and authority only)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.agent_user:

``yk8s.ch-k8s-lbaas.agent_user``
################################



**Type:**::

  POSIX user name


**Default:**::

  "ch-k8s-lbaas-agent"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.controller_repo:

``yk8s.ch-k8s-lbaas.controller_repo``
#####################################



**Type:**::

  Kubernetes container image reference


**Default:**::

  "registry.gitlab.com/yaook/ch-k8s-lbaas/controller"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.controller_resources:

``yk8s.ch-k8s-lbaas.controller_resources``
##########################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.controller_resources.limits.cpu:

``yk8s.ch-k8s-lbaas.controller_resources.limits.cpu``
#####################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.controller_resources.limits.memory:

``yk8s.ch-k8s-lbaas.controller_resources.limits.memory``
########################################################

Request and limit for the LBaaS controller

**Type:**::

  null or Kubernetes quantity


**Default:**::

  "256Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.controller_resources.requests.cpu:

``yk8s.ch-k8s-lbaas.controller_resources.requests.cpu``
#######################################################

Request and limit for the LBaaS controller

**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.controller_resources.requests.memory:

``yk8s.ch-k8s-lbaas.controller_resources.requests.memory``
##########################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.ch-k8s-lbaas.controller_resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.enable_snat:

``yk8s.ch-k8s-lbaas.enable_snat``
#################################

Whether to enable source-nat'ing by the ch-k8s-lbaas-agents running on the frontend nodes.

Disabling this has a similar effect as a direct server return.
It allows to see the real source IP of traffic sent to a LoadBalancer-service.

After reconfiguring this option, execute the following:

.. code::

  $ ./managed-k8s/actions/apply-k8s-supplements.sh install-ch-k8s-lbaas.yaml

to rollout necessary changes.

Running on OpenStack
""""""""""""""""""""

If source-nat'ing is disabled, the frontend nodes will be configured to act as gateway
for the Kubernetes nodes. They will propagate routes via BGP overwriting the default routes of
Kubernetes nodes such that **all** traffic is routed via the VIP by default.

.. important:: Administrative Traffic

  Traffic sent via Wireguard is still SNAT'ed as otherwise
  freshly provisioned nodes can't be administered.

.. warning:: Implications when running on OpenStack

  Disabling source-nat'ing has some implications:

  1. If a failover occurs on the frontend nodes, **all** connections are impacted,
     not only connections to LoadBalancer-Services.
  2. The source IP of Kubernetes nodes as seen by the outside world changes from
     the OpenStack router IP to the Gateway's VIP.
  3. It's not possible to attach floating IPs to Kubernetes nodes anymore due to
     routing asymmetry.

Be aware, that the frontend nodes must be potent enough to handle the increased amount of traffic
if source-nat'ing is disabled, as they could become the bottleneck otherwise.

**Type:**::

  boolean


**Default:**::

  true


**Example:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.enabled:

``yk8s.ch-k8s-lbaas.enabled``
#############################

Whether to enable our LBaas service.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.port_manager:

``yk8s.ch-k8s-lbaas.port_manager``
##################################

Configure which IP address ("port") manager to use. Two options are available:

* openstack: Uses OpenStack and the Tarook gateway nodes to provision
  LBaaS IP addresses ports.
* static: Uses a fixed set of IP addresses to use for load balancing. When the
  static port manager is used,
  :ref:`configuration-options.yk8s.ch-k8s-lbaas.agent_urls`
  and
  :ref:`configuration-options.yk8s.ch-k8s-lbaas.static_ipv4_addresses`
  must be set as well.


**Type:**::

  one of "openstack", "static"


**Default:**::

  "openstack"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.shared_secret:

``yk8s.ch-k8s-lbaas.shared_secret``
###################################

.. attention:: DEPRECATED

   This option is going to be removed soon
   since the shared secret is now stored in and automatically handled via Vault.

A unique, random, base64-encoded secret.
To generate such a secret, you can use the following command:
$ dd if=/dev/urandom bs=16 count=1 status=none | base64


**Type:**::

  null or Base64 encoded string


**Default:**::

  null


**Example:**::

  "Example+NZHrRAV9AAN83T7Hc6wVk9IGzPou6UjwWhL+4hu1I4XPj+YG/AgKiFIc1a1EzmQKax9VAj6P/oA45w=="


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.static_ipv4_addresses:

``yk8s.ch-k8s-lbaas.static_ipv4_addresses``
###########################################

List of IPv4 addresses which are usable for the static port manager. It is
your responsibility to ensure that the node(s) which run the agent(s) receive
traffic for these IPv4 addresses.


**Type:**::

  list of IPv4 address in four-octets decimal notation


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.use_bgp:

``yk8s.ch-k8s-lbaas.use_bgp``
#############################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.use_floating_ips:

``yk8s.ch-k8s-lbaas.use_floating_ips``
######################################

Whether to enable the use of floating IPs.

**Type:**::

  boolean


**Default:**::

  true


**Example:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix


.. _configuration-options.yk8s.ch-k8s-lbaas.version:

``yk8s.ch-k8s-lbaas.version``
#############################



**Type:**::

  OCI image tag


**Default:**::

  "0.9.0"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ch-k8s-lbaas.nix

