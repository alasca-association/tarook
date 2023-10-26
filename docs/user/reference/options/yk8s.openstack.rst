.. _configuration-options.yk8s.openstack:

yk8s.openstack
^^^^^^^^^^^^^^


.. note::

   There is a variable ``nodes`` to configure
   the k8s master and worker servers.
   The ``role`` attribute must be used to distinguish both [1]_.

   The amount of gateway nodes can be controlled with the `gateway_count` variable.
   It defaults to the number of elements in the ``azs`` array when
   ``spread_gateways_across_azs=true`` and 3 otherwise.

.. [1] Caveat: Changing the role of a OpenTofu node
               will completely rebuild the node.

.. attention::

    You must configure at least one master node.

You can add and delete OpenTofu nodes simply
by adding and removing their entries to/from the config
or tuning ``gateway_count`` for gateway nodes.
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

- for master/worker nodes:
  ``infra.cluster_name`` ``<the nodes' key in openstack.nodes>``

- for gateway nodes:
  ``infra.cluster_name`` ``openstack.gateway_defaults.common_name`` ``<numeric-index>``

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

.. _configuration-options.yk8s.openstack.azs:

``yk8s.openstack.azs``
######################

Defines the availability zones of your cloud to use for the creation of servers.

**Type:**::

  list of non-empty string


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.check_credentials:

``yk8s.openstack.check_credentials``
####################################

OpenStack credential checks
Terrible things will happen when certain tasks are run and OpenStack credentials are not sourced.
Okay, maybe not so terrible after all, but the templates do not check if certain values exist.
Hence config files with empty credentials are written. The LCM will execute a simple check to see
if you provided valid credentials as a sanity check if you're on openstack and this option is set
to true.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.cinder_volume_type:

``yk8s.openstack.cinder_volume_type``
#####################################

Use a specific volume type for the csi-sc-cinderplugin StorageClass.
If unset, no volume type is explicitly set and the default volume type
of the IaaS-layer is used.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.create_root_disk_on_volume:

``yk8s.openstack.create_root_disk_on_volume``
#############################################

Whether to enable creation of root disk volumes.
If true, create block volume for each instance and boot from there.
Equivalent to ``openstack server create --boot-from-volume […]``.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.dns_nameservers_v4:

``yk8s.openstack.dns_nameservers_v4``
#####################################

A list of IPv4 addresses which will be configured as DNS nameservers of the IPv4 subnet.

**Type:**::

  list of non-empty string


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.enabled:

``yk8s.openstack.enabled``
##########################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.gateway_count:

``yk8s.openstack.gateway_count``
################################

Amount of gateway nodes to create. (default: 0 --> one for each availability zone when 'spread_gateways_across_azs=true', 3 otherwise)

**Type:**::

  positive integer, meaning >0


**Default:**::

  0


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.gateway_defaults.common_name:

``yk8s.openstack.gateway_defaults.common_name``
###############################################



**Type:**::

  string


**Default:**::

  "gw-"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.gateway_defaults.flavor:

``yk8s.openstack.gateway_defaults.flavor``
##########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.gateway_defaults.image:

``yk8s.openstack.gateway_defaults.image``
#########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.gateway_defaults.root_disk_size:

``yk8s.openstack.gateway_defaults.root_disk_size``
##################################################

Only apples if 'openstack.create_root_disk_on_volume=true'.


**Type:**::

  positive integer, meaning >0


**Default:**::

  10


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.gateway_defaults.root_disk_volume_type:

``yk8s.openstack.gateway_defaults.root_disk_volume_type``
#########################################################

Only apples if 'openstack.create_root_disk_on_volume=true'.
If left empty, the default of the IaaS environment will be used.


**Type:**::

  string


**Default:**::

  ""


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.keypair:

``yk8s.openstack.keypair``
##########################

Will most of the time be set via the environment variable TF_VAR_keypair


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.master_defaults.flavor:

``yk8s.openstack.master_defaults.flavor``
#########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.master_defaults.image:

``yk8s.openstack.master_defaults.image``
########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.master_defaults.root_disk_size:

``yk8s.openstack.master_defaults.root_disk_size``
#################################################

Only apples if 'openstack.create_root_disk_on_volume=true'.


**Type:**::

  positive integer, meaning >0


**Default:**::

  50


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.master_defaults.root_disk_volume_type:

``yk8s.openstack.master_defaults.root_disk_volume_type``
########################################################

Only apples if 'openstack.create_root_disk_on_volume=true'.
If left empty, the default of the IaaS environment will be used.


**Type:**::

  string


**Default:**::

  ""


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.network_mtu:

``yk8s.openstack.network_mtu``
##############################

MTU for the network used for the cluster.

**Type:**::

  positive integer, meaning >0


**Default:**::

  1450


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.network_name:

``yk8s.openstack.network_name``
###############################

Name of the internal OpenStack network. This field becomes important if a VM is
attached to two networks but the controller-manager should only pick up one. If
you don't understand the purpose of this field, there's a very high chance you
won't need to touch it.
Note: This network name isn't fetched automagically (by terraform) on purpose
because there might be situations where the CCM should not pick the managed network.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Example:**::

  "\${config.yk8s.infra.cluster_name}-network"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.nodes:

``yk8s.openstack.nodes``
########################

User defined attribute set of control plane and worker nodes to be created with specified values

At least one node with role=master must be given.


**Type:**::

  attribute set of (submodule)


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.nodes.<name>.anti_affinity_group:

``yk8s.openstack.nodes.<name>.anti_affinity_group``
###################################################

'anti_affinity_group' must not be set when role!="worker"
Leaving 'anti_affinity_group' empty means to not join any anti affinity group


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.nodes.<name>.az:

``yk8s.openstack.nodes.<name>.az``
##################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.nodes.<name>.flavor:

``yk8s.openstack.nodes.<name>.flavor``
######################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.nodes.<name>.image:

``yk8s.openstack.nodes.<name>.image``
#####################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.nodes.<name>.role:

``yk8s.openstack.nodes.<name>.role``
####################################



**Type:**::

  string matching the pattern master|worker


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.nodes.<name>.root_disk_size:

``yk8s.openstack.nodes.<name>.root_disk_size``
##############################################



**Type:**::

  null or (positive integer, meaning >0)


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.nodes.<name>.root_disk_volume_type:

``yk8s.openstack.nodes.<name>.root_disk_volume_type``
#####################################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.public_network:

``yk8s.openstack.public_network``
#################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.spread_gateways_across_azs:

``yk8s.openstack.spread_gateways_across_azs``
#############################################

If true, spawn a gateway node in each availability zone listed in 'azs'. Otherwise leave the distribution to the cloud controller.

**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.thanos_delete_container:

``yk8s.openstack.thanos_delete_container``
##########################################



**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.worker_defaults.anti_affinity_group:

``yk8s.openstack.worker_defaults.anti_affinity_group``
######################################################

Leaving this empty means to not join any anti affinity group


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.worker_defaults.flavor:

``yk8s.openstack.worker_defaults.flavor``
#########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.worker_defaults.image:

``yk8s.openstack.worker_defaults.image``
########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.worker_defaults.root_disk_size:

``yk8s.openstack.worker_defaults.root_disk_size``
#################################################

Only apples if 'openstack.create_root_disk_on_volume=true'.


**Type:**::

  positive integer, meaning >0


**Default:**::

  50


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix


.. _configuration-options.yk8s.openstack.worker_defaults.root_disk_volume_type:

``yk8s.openstack.worker_defaults.root_disk_volume_type``
########################################################

Only apples if 'openstack.create_root_disk_on_volume=true'.
If left empty, the default of the IaaS environment will be used.


**Type:**::

  string


**Default:**::

  ""


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/openstack.nix

