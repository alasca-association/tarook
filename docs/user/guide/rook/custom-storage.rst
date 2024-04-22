Custom Storage Configuration
============================

.. hint::

   Custom storage configuration is only available for rook
   v1.6 and above.

Custom storage configuration is i.e. needed for rook/ceph clusters not
running on OpenStack but on bare metal. The default cinder storage class
used to set up OSDs is not available if you’re not running on OpenStack.
In such an environment, one wants to directly define fine-granular the
nodes to used and their devices.

If you’re not running on OpenStack you need to set the following
variable to ``false``:

.. code:: toml

   on_openstack = false

.. note::

   All the subsequent described configuration does only take
   effect if you disabled ``on_openstack``.

You can configure to automatically use all available nodes and/or
devices:

.. code:: toml

   use_all_available_nodes = true
   use_all_available_devices = true

You do also have the option to manually define the to be used nodes,
their configuration and devices of the configured nodes as well as
device-specific configurations. For these configurations to take effect
one must set ``use_all_available_nodes`` and
``use_all_available_devices`` to ``false``.

In the following an example for a fine-granular
node-device-configuration can be found:

.. code:: toml

   # One node
   [[k8s-service-layer.rook.nodes]]
   name = "HOSTNAME_OF_NODE_1"
   # Node-specific configuration
   [k8s-service-layer.rook.nodes.config]
   encryptedDevice = "true"
   # A node devices and its configuration
   [k8s-service-layer.rook.nodes.devices."/dev/disk/by-id/x".config]
   metadataDevice = "nvme0n1"
   # Another node devices and its configuration
   [k8s-service-layer.rook.nodes.devices."/dev/disk/by-id/x".config]
   encryptedDevice = true
   metadataDevice = "nvme0n1"

   # Another node
   [[k8s-service-layer.rook.nodes]]
   name = "HOSTNAME_OF_NODE_2"
   [k8s-service-layer.rook.nodes.devices."/dev/disk/by-id/x".config]
   metadataDevice = "nvme0n1"

You can use the tool ``tools/assemble_cephcluster_storage_nodes_yaml.py``
to generate node-device-configuration to be included in the CephCluster
manifest. The output can manually transformed to be included in the
``config.toml`` file as shown above. The tool has to be executed on each
storage node after the operation system has been installed. It automatically
determines the disks suitable for OSDs and metadata devices and distributes
the OSDs evenly across the metadata devices. This half-automated way of
generating node-device-configuration helps to avoid misconfiguration and
thus to avoid time consuming correction of a wrongly deployed Ceph cluster.

For node- and device-specific configuration options please refer to the
`official rook documentation <https://rook.io/docs/rook/v1.9/CRDs/Cluster/ceph-cluster-crd/#cluster-settings>`__.
