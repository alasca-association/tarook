.. _configuration-options.yk8s.openstack:

yk8s.openstack
^^^^^^^^^^^^^^


.. note::

    :ref:`configuration-options.yk8s.openstack.nodes`
    allows you to configure
    the Kubernetes master and worker servers.
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

.. _configuration-options.yk8s.openstack.azs:

``yk8s.openstack.azs``
######################

Availability zones of the underlying Openstack cloud to use for the creation of servers.

**Type:**::

  list of non-empty string


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.check_credentials:

``yk8s.openstack.check_credentials``
####################################

Whether to enable OpenStack credential checks
Terrible things will happen when certain tasks are run and OpenStack credentials are not sourced.
Okay, maybe not so terrible after all, but the templates do not check if certain values exist.
Hence config files with empty credentials are written. The LCM will execute a simple check to see
if you provided valid credentials as a sanity check if you're on openstack and this option is set
to true.
.

**Type:**::

  boolean


**Default:**::

  true


**Example:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cinder.enable_topology:

``yk8s.openstack.cinder.enable_topology``
#########################################

Whether to enable cinder topology.
This flag enables the topology feature gate of the cinder controller plugin.
Its purpose is to allocate volumes from cinder which are in the same AZ as
the worker node to which the volume should be attached.
Important: Cinder must support AZs and the AZs must match the AZs used by nova!
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cinder.helm.chart_ref:

``yk8s.openstack.cinder.helm.chart_ref``
########################################

The chart reference (relative to the repository) of the Cinder CSI driver plugin Helm chart.


**Type:**::

  RFC3986 relative URL path


**Default:**::

  "openstack-cinder-csi"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cinder.helm.chart_repo_url:

``yk8s.openstack.cinder.helm.chart_repo_url``
#############################################

The URL to the Helm repository for the Cinder CSI driver plugin Helm chart.


**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://kubernetes.github.io/cloud-provider-openstack"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cinder.helm.chart_version:

``yk8s.openstack.cinder.helm.chart_version``
############################################

Version of the Cinder CSI driver plugin Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "2.35.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cinder.helm.release_name:

``yk8s.openstack.cinder.helm.release_name``
###########################################

The release name inside the cluster for Cinder CSI driver plugin.


**Type:**::

  non-empty string


**Default:**::

  "cinder-csi"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cinder.helm.release_namespace:

``yk8s.openstack.cinder.helm.release_namespace``
################################################

The namespace in which to install Cinder CSI driver plugin.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "kube-system"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cinder.helm.values:

``yk8s.openstack.cinder.helm.values``
#####################################

Helm values for the Cinder CSI driver plugin helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://github.com/kubernetes/cloud-provider-openstack/blob/master/charts/cinder-csi-plugin/values.yaml


**Type:**::

  open submodule of (attribute set containing JSON compatible values)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cinder.volume_type:

``yk8s.openstack.cinder.volume_type``
#####################################

Use a specific volume type for the csi-sc-cinderplugin StorageClass.
If unset, no volume type is explicitly set and the default volume type
of the IaaS-layer is used.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cloud_controller_manager.helm.chart_ref:

``yk8s.openstack.cloud_controller_manager.helm.chart_ref``
##########################################################

The chart reference (relative to the repository) of the Openstack Cloud Controller Manager Helm chart.


**Type:**::

  RFC3986 relative URL path


**Default:**::

  "openstack-cloud-controller-manager"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cloud_controller_manager.helm.chart_repo_url:

``yk8s.openstack.cloud_controller_manager.helm.chart_repo_url``
###############################################################

The URL to the Helm repository for the Openstack Cloud Controller Manager Helm chart.


**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://kubernetes.github.io/cloud-provider-openstack"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cloud_controller_manager.helm.chart_version:

``yk8s.openstack.cloud_controller_manager.helm.chart_version``
##############################################################

Version of the Openstack Cloud Controller Manager Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "2.36.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cloud_controller_manager.helm.release_name:

``yk8s.openstack.cloud_controller_manager.helm.release_name``
#############################################################

The release name inside the cluster for Openstack Cloud Controller Manager.


**Type:**::

  non-empty string


**Default:**::

  "openstack-cloud-controller-manager"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cloud_controller_manager.helm.release_namespace:

``yk8s.openstack.cloud_controller_manager.helm.release_namespace``
##################################################################

The namespace in which to install Openstack Cloud Controller Manager.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "kube-system"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.cloud_controller_manager.helm.values:

``yk8s.openstack.cloud_controller_manager.helm.values``
#######################################################

Helm values for the Openstack Cloud Controller Manager helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://github.com/kubernetes/cloud-provider-openstack/blob/master/charts/openstack-cloud-controller-manager/values.yaml


**Type:**::

  open submodule of (attribute set containing JSON compatible values)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.create_root_disk_on_volume:

``yk8s.openstack.create_root_disk_on_volume``
#############################################

Whether to enable creation of root disk volumes for all instances.
If true, create block volume for each instance and boot from there.

Equivalent to ``openstack server create --boot-from-volume […]``.

This is option is inferior to:

- :ref:`configuration-options.yk8s.openstack.gateway_defaults.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.master_defaults.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.worker_defaults.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume`

.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.dns_nameservers_v4:

``yk8s.openstack.dns_nameservers_v4``
#####################################

A list of IPv4 addresses which will be configured as DNS nameservers of the IPv4 subnet.

**Type:**::

  list of IPv4 address in four-octets decimal notation


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.enabled:

``yk8s.openstack.enabled``
##########################

Whether to build the cluster on top of Openstack.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.gateway_count:

``yk8s.openstack.gateway_count``
################################

Amount of gateway nodes to create.

Defaults to 3
unless
:ref:`configuration-options.yk8s.openstack.spread_gateways_across_azs`
is set to ``true``
in which case it will match the amount of availability zones by default.


**Type:**::

  positive integer, meaning >0


**Default:**::

  0


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.gateway_defaults.common_name:

``yk8s.openstack.gateway_defaults.common_name``
###############################################



**Type:**::

  string


**Default:**::

  "gw-"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.gateway_defaults.create_root_disk_on_volume:

``yk8s.openstack.gateway_defaults.create_root_disk_on_volume``
##############################################################

Enable creation of root disk volume for gateways.
If true, create block volume for all gateways and boot from there.

Equivalent to ``openstack server create --boot-from-volume […]``

This option takes precedence over:

- :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`



**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.gateway_defaults.flavor:

``yk8s.openstack.gateway_defaults.flavor``
##########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.gateway_defaults.image:

``yk8s.openstack.gateway_defaults.image``
#########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.gateway_defaults.root_disk_size:

``yk8s.openstack.gateway_defaults.root_disk_size``
##################################################

If null, the disk size of the configured flavor will be used.


**Type:**::

  null or (positive integer, meaning >0)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.gateway_defaults.root_disk_volume_type:

``yk8s.openstack.gateway_defaults.root_disk_volume_type``
#########################################################

If null, the default of the IaaS environment will be used.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.keypair:

``yk8s.openstack.keypair``
##########################

Name of the SSH public key in your cloud environment

Will most of the time be set via the environment variable TF_VAR_keypair


**Type:**::

  null or non-empty string


**Default:**::

  "\${var.keypair}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.master_defaults.create_root_disk_on_volume:

``yk8s.openstack.master_defaults.create_root_disk_on_volume``
#############################################################

Enable creation of root disk volume for masters by default.
If true, create block volume for masters by default and boot from there.

Equivalent to ``openstack server create --boot-from-volume […]``

This option takes precedence over:

- :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`

but is inferior to:

- :ref:`configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume`



**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.master_defaults.flavor:

``yk8s.openstack.master_defaults.flavor``
#########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.master_defaults.image:

``yk8s.openstack.master_defaults.image``
########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.master_defaults.root_disk_size:

``yk8s.openstack.master_defaults.root_disk_size``
#################################################

If null, the disk size of the configured flavor will be used.

This will only take effect if one of the following

- :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.master_defaults.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume` (for each master node)

is set to ``true``.


**Type:**::

  null or (positive integer, meaning >0)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.master_defaults.root_disk_volume_type:

``yk8s.openstack.master_defaults.root_disk_volume_type``
########################################################

If null, the default of the IaaS environment will be used.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.network_mtu:

``yk8s.openstack.network_mtu``
##############################

MTU for the OpenStack network used for the cluster.

.. note::

   Changes are ignored by Terraform once the network has been created.



**Type:**::

  positive integer, meaning >0


**Default:**::

  1450


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


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

  "${config.yk8s.infra.cluster_name}-network"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes:

``yk8s.openstack.nodes``
########################

User defined attribute set of control plane and worker nodes to be created with specified values

At least one node with role=master must be given.

You may also specify those attributes or a subset of them
using :ref:`yk8s.openstack.{master,worker}_defaults <configuration-options.yk8s.openstack>`.

Gateways are created automatically, and should not be explicitly added here.


**Type:**::

  attribute set of (submodule)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes.<name>.anti_affinity_group:

``yk8s.openstack.nodes.<name>.anti_affinity_group``
###################################################

Must not be set when role!="worker".
If left empty no anti affinity group will be joined.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes.<name>.az:

``yk8s.openstack.nodes.<name>.az``
##################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume:

``yk8s.openstack.nodes.<name>.create_root_disk_on_volume``
##########################################################

Enable creation of root disk volume for this instance.
If true, create block volume for this instance and boot from there.

Equivalent to ``openstack server create --boot-from-volume […]``.

This option takes precedence over:

- :ref:`configuration-options.yk8s.openstack.gateway_defaults.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.master_defaults.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.worker_defaults.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`



**Type:**::

  null or boolean


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes.<name>.flavor:

``yk8s.openstack.nodes.<name>.flavor``
######################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes.<name>.image:

``yk8s.openstack.nodes.<name>.image``
#####################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes.<name>.role:

``yk8s.openstack.nodes.<name>.role``
####################################



**Type:**::

  one of "master", "worker", "gateway"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes.<name>.root_disk_size:

``yk8s.openstack.nodes.<name>.root_disk_size``
##############################################

If null, the disk size of the configured flavor will be used.

This will only take effect if one of the following

- :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.worker_defaults.create_root_disk_on_volume`
  (if :ref:`configuration-options.yk8s.openstack.nodes.<name>.role` is ``worker``)
- :ref:`configuration-options.yk8s.openstack.master_defaults.create_root_disk_on_volume`
  (if :ref:`configuration-options.yk8s.openstack.nodes.<name>.role` is ``master``)
- :ref:`configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume`

is set to ``true``.


**Type:**::

  null or (positive integer, meaning >0)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.nodes.<name>.root_disk_volume_type:

``yk8s.openstack.nodes.<name>.root_disk_volume_type``
#####################################################



**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.public_network:

``yk8s.openstack.public_network``
#################################

Name of the Openstack provider network to use


**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.spread_gateways_across_azs:

``yk8s.openstack.spread_gateways_across_azs``
#############################################

If true, spawn a gateway node in each availability zone listed in :ref:`configuration-options.yk8s.openstack.spread_gateways_across_azs`, Otherwise leave the distribution to the cloud controller.

**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.thanos_delete_container:

``yk8s.openstack.thanos_delete_container``
##########################################

Whether to enable deletion of the Thanos object storage container
in case
:ref:`configuration-options.yk8s.k8s-service-layer.prometheus.use_thanos`
AND :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.manage_thanos_bucket`
are switched off
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.worker_defaults.anti_affinity_group:

``yk8s.openstack.worker_defaults.anti_affinity_group``
######################################################

Leaving this empty means to not join any anti affinity group


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.worker_defaults.create_root_disk_on_volume:

``yk8s.openstack.worker_defaults.create_root_disk_on_volume``
#############################################################

Enable creation of root disk volume for workers by default.
If true, create block volume for workers by default and boot from there.

Equivalent to ``openstack server create --boot-from-volume […]``.

This option takes precedence over:

- :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`

but is inferior to:

- :ref:`configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume`



**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.worker_defaults.flavor:

``yk8s.openstack.worker_defaults.flavor``
#########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.worker_defaults.image:

``yk8s.openstack.worker_defaults.image``
########################################



**Type:**::

  non-empty string


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.worker_defaults.root_disk_size:

``yk8s.openstack.worker_defaults.root_disk_size``
#################################################

If null, the disk size of the configured flavor will be used.

This will only take effect if one of the following

- :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.worker_defaults.create_root_disk_on_volume`
- :ref:`configuration-options.yk8s.openstack.nodes.<name>.create_root_disk_on_volume` (for each worker node)

is set to ``true``.


**Type:**::

  null or (positive integer, meaning >0)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack


.. _configuration-options.yk8s.openstack.worker_defaults.root_disk_volume_type:

``yk8s.openstack.worker_defaults.root_disk_volume_type``
########################################################

If null, the default of the IaaS environment will be used.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/openstack

