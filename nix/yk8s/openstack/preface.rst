.. note::

    :ref:`configuration-options.yk8s.openstack.nodes`
    allows you to configure
    the k8s master and worker servers.
    The ``role`` attribute must be used to distinguish both [1]_.

    The amount of gateway nodes can be controlled with
    :ref:`configuration-options.yk8s.openstack.gateway_count`.

.. [1] Caveat: Changing the role of a Terraform node
                will completely rebuild the node.

.. attention::

    You must configure at least one master node.

You can add and delete Terraform nodes simply
by adding and removing their entries to/from the config
or tuning :ref:`configuration-options.yk8s.openstack.gateway_count` for gateway nodes.
Consider the following example:

.. code:: diff

    openstack = {

    -  gateway_count = 3;
    +  gateway_count = 2;                 # <-- one gateway gets deleted

    nodes = {
        worker-0 = {
        role = "worker";
        flavor = "M";
        image = "Debian 12 (bookworm)";
        };
    -    worker-1 = {                     # <-- gets deleted
    -      role = "worker";
    -      flavor = "M";
    -    };
        worker-2 = {
        role = "worker";
        flavor = "L";
        };
    +    mon1 = {                         # <-- gets created
    +      role = "worker";
    +      flavor = "S";
    +      image = "Ubuntu 22.04 LTS x64";
    +    };
    };
    };

The name of an OpenStack node is composed from the following parts:

- for master/worker nodes: ``yk8s.infra.cluster_name`` ``<the nodes' key in yk8s.openstack.nodes>``

- for gateway nodes: ``yk8s.infra.cluster_name`` ``yk8s.openstack.gateway_defaults.common_name`` ``<numeric-index>``

.. code:: nix

    openstack = {

    cluster_name = "yk8s";
    gateway_count = 1;
    #....

    gateway_defaults.common_name = "gateway-";

    nodes.master-x.role = "master";
    nodes.worker-a.role = "worker";

    # yields the following node names:
    # - yk8s-gateway-0
    # - yk8s-master-x
    # - yk8s-worker-a
