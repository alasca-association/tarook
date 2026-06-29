.. _configuration-options.yk8s.proxmox:

yk8s.proxmox
^^^^^^^^^^^^


See :ref:`Proxmox Credentials <environmental-variables.proxmox-credentials>` for the environment variables necessary for Proxmox.

.. _configuration-options.yk8s.proxmox.clone.node_name:

``yk8s.proxmox.clone.node_name``
################################

The name of the host on which the source VM resides.


**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.clone.vm_id:

``yk8s.proxmox.clone.vm_id``
############################

The identifier for the VM from which nodes should be cloned. Must be a VM with Ubuntu 24.04 LTS with Cloud-Init support.


**Type:**::

  integer between 100 and 999999999 (both inclusive)


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.datastore_id:

``yk8s.proxmox.datastore_id``
#############################

The identifier for the datastore for root disks.


**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.dns_servers:

``yk8s.proxmox.dns_servers``
############################



**Type:**::

  list of (IPv4 address in four-octets decimal notation or IPv6 address in colon-hexadecimal notation)


**Default:**::

  (lib.optional config.yk8s.infra.ipv4_enabled config.yk8s.proxmox.ipv4_gateway_address)
  ++ (lib.optional config.yk8s.infra.ipv6_enabled config.yk8s.proxmox.ipv6_gateway_address)
  


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.enabled:

``yk8s.proxmox.enabled``
########################

Whether to build the cluster on top of Proxmox

.. note::

  Proxmox support is currently in ALPHA state. There are no guarantees towards stability or compatibility yet. In particular: Configuration may change in a breaking manner even in patch versions.



**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.ipv4_gateway_address:

``yk8s.proxmox.ipv4_gateway_address``
#####################################

The IPv4 address that should be configured as the default gateway on each node.

Must be set if config.yk8s.infra.ipv4_enabled==true


**Type:**::

  null or IPv4 address in four-octets decimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.ipv6_gateway_address:

``yk8s.proxmox.ipv6_gateway_address``
#####################################

The IPv6 address that should be configured as the default gateway on each node.

Must be set if config.yk8s.infra.ipv6_enabled==true


**Type:**::

  null or IPv6 address in colon-hexadecimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes:

``yk8s.proxmox.nodes``
######################

User defined attribute set of control plane and worker nodes to be created with specified values

At least one node with role=master must be given.


**Type:**::

  attribute set of (submodule)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.cores:

``yk8s.proxmox.nodes.<name>.cores``
###################################

Amount of CPU cores to be assigned to the VM


**Type:**::

  positive integer, meaning >0


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.extraConfig:

``yk8s.proxmox.nodes.<name>.extraConfig``
#########################################

Any additional values
that the ``bpg/proxmox`` Terraform provider plugin accepts
for a VM.
See https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm

Note that these are not checked and cannot override values set by other options.
Note that setting ``user_data_file_id`` is currently not supported.


**Type:**::

  attribute set of anything


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.ipv4_address:

``yk8s.proxmox.nodes.<name>.ipv4_address``
##########################################

Must be set if config.yk8s.infra.ipv4_enabled==true


**Type:**::

  null or IPv4 address in four-octets decimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.ipv6_address:

``yk8s.proxmox.nodes.<name>.ipv6_address``
##########################################

Must be set if config.yk8s.infra.ipv6_enabled==true


**Type:**::

  null or IPv6 address in colon-hexadecimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.memory:

``yk8s.proxmox.nodes.<name>.memory``
####################################

Amount of dedicated RAM in megabytes to be assigned to the VM


**Type:**::

  positive integer, meaning >0


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.network_device:

``yk8s.proxmox.nodes.<name>.network_device``
############################################

The settings of the VM's primary network device


**Type:**::

  submodule


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.network_device.bridge:

``yk8s.proxmox.nodes.<name>.network_device.bridge``
###################################################

The name of the network bridge


**Type:**::

  non-empty string


**Default:**::

  "vmbr0"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.network_device.firewall:

``yk8s.proxmox.nodes.<name>.network_device.firewall``
#####################################################

whether this interface's firewall rules should be used


**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.network_device.mtu:

``yk8s.proxmox.nodes.<name>.network_device.mtu``
################################################

Force MTU, for VirtIO only. Set to 1 to use the bridge MTU.
Cannot be larger than the bridge MTU.


**Type:**::

  null or (positive integer, meaning >0)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.network_device.trunks:

``yk8s.proxmox.nodes.<name>.network_device.trunks``
###################################################

List of VLAN trunks (``[10 20 30]``).
Note that the VLAN-aware feature need to be enabled on the PVE Linux Bridge to use trunks.


**Type:**::

  list of (positive integer, meaning >0)


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.network_device.vlan_id:

``yk8s.proxmox.nodes.<name>.network_device.vlan_id``
####################################################

The VLAN identifier


**Type:**::

  null or integer between 0 and 4096 (both inclusive)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.role:

``yk8s.proxmox.nodes.<name>.role``
##################################



**Type:**::

  one of "master", "worker"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.root_disk_size:

``yk8s.proxmox.nodes.<name>.root_disk_size``
############################################

Amount of root disk capacity in gigabytes to be assigned to the VM


**Type:**::

  positive integer, meaning >0


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.nodes.<name>.target_node:

``yk8s.proxmox.nodes.<name>.target_node``
#########################################

Host onto which to schedule the VM


**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox


.. _configuration-options.yk8s.proxmox.pool_id:

``yk8s.proxmox.pool_id``
########################

The identifier for a pool to assign the virtual machines to.


**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/proxmox

