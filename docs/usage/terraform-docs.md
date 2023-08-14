# Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |

# Providers

| Name | Version |
|------|---------|
| local | 2.4.0 |
| openstack | 1.51.1 |
| template | 2.2.0 |

# Modules

No modules.

# Resources

| Name | Type |
|------|------|
| [local_file.final_group_all](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.final_networking](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.inventory_stage2](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.inventory_stage3](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.trampoline_gateways](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [openstack_blockstorage_volume_v2.gateway-volume](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/blockstorage_volume_v2) | resource |
| [openstack_blockstorage_volume_v2.master-volume](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/blockstorage_volume_v2) | resource |
| [openstack_blockstorage_volume_v2.worker-volume](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/blockstorage_volume_v2) | resource |
| [openstack_compute_floatingip_associate_v2.gateway](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_floatingip_associate_v2) | resource |
| [openstack_compute_instance_v2.gateway](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_instance_v2) | resource |
| [openstack_compute_instance_v2.master](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_instance_v2) | resource |
| [openstack_compute_instance_v2.worker](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_instance_v2) | resource |
| [openstack_compute_servergroup_v2.server_group](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_servergroup_v2) | resource |
| [openstack_networking_floatingip_v2.gateway](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_floatingip_v2) | resource |
| [openstack_networking_floatingip_v2.gw_vip_fip](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_floatingip_v2) | resource |
| [openstack_networking_network_v2.cluster_network](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_network_v2) | resource |
| [openstack_networking_port_v2.gateway](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_port_v2) | resource |
| [openstack_networking_port_v2.gw_vip_port](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_port_v2) | resource |
| [openstack_networking_port_v2.master](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_port_v2) | resource |
| [openstack_networking_port_v2.worker](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_port_v2) | resource |
| [openstack_networking_router_interface_v2.cluster_router_iface](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_router_interface_v2) | resource |
| [openstack_networking_router_interface_v2.cluster_router_iface_v6](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_router_interface_v2) | resource |
| [openstack_networking_router_v2.cluster_router](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_router_v2) | resource |
| [openstack_networking_subnet_v2.cluster_subnet](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_subnet_v2) | resource |
| [openstack_networking_subnet_v2.cluster_v6_subnet](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_subnet_v2) | resource |
| [openstack_objectstorage_container_v1.thanos_data](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/objectstorage_container_v1) | resource |
| [openstack_compute_flavor_v2.gateway](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/compute_flavor_v2) | data source |
| [openstack_compute_flavor_v2.master](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/compute_flavor_v2) | data source |
| [openstack_compute_flavor_v2.worker](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/compute_flavor_v2) | data source |
| [openstack_images_image_v2.gateway](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/images_image_v2) | data source |
| [openstack_images_image_v2.master](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/images_image_v2) | data source |
| [openstack_images_image_v2.worker](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/images_image_v2) | data source |
| [openstack_networking_network_v2.public_network](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/networking_network_v2) | data source |
| [template_file.trampoline_gateways](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

# Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azs | If 'enable\_az\_management=true' defines which availability zones of your cloud to use to distribute the spawned server for better HA. Additionally the count of the array will define how many gateway server will be spawned. The naming of the elements doesn't matter if 'enable\_az\_management=false'. It is also used for unique naming of gateways. | `list(string)` | <pre>[<br>  "AZ1",<br>  "AZ2",<br>  "AZ3"<br>]</pre> | no |
| cluster\_name | n/a | `string` | `"managed-k8s"` | no |
| create\_root\_disk\_on\_volume | n/a | `bool` | `false` | no |
| default\_master\_flavor | n/a | `string` | `"M"` | no |
| default\_master\_image\_name | n/a | `string` | `"Ubuntu 20.04 LTS x64"` | no |
| default\_master\_root\_disk\_size | If 'create\_root\_disk\_on\_volume=true', the master flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size. | `number` | `50` | no |
| default\_worker\_flavor | n/a | `string` | `"M"` | no |
| default\_worker\_image\_name | n/a | `string` | `"Ubuntu 20.04 LTS x64"` | no |
| default\_worker\_root\_disk\_size | If 'create\_root\_disk\_on\_volume=true', the worker flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size. | `number` | `50` | no |
| dualstack\_support | If set to true, dualstack support related resources will be (re-)created | `bool` | n/a | yes |
| enable\_az\_management | If set to false, the availability zone of instances will not be managed. This is useful in CI environments if the Cloud Is Full. | `bool` | `true` | no |
| gateway\_flavor | n/a | `string` | `"XS"` | no |
| gateway\_image\_name | n/a | `string` | `"Debian 12 (bookworm)"` | no |
| gateway\_root\_disk\_volume\_size | If 'create\_root\_disk\_on\_volume=true' and the gateway flavor does not specify a disk size, the root disk volume will have this size. | `number` | `10` | no |
| gateway\_root\_disk\_volume\_type | If 'create\_root\_disk\_on\_volume=true', set the volume type of the root disk volume for Gateways. Can't be configured separately for each instance | `string` | `""` | no |
| haproxy\_ports | n/a | `list(number)` | <pre>[<br>  30000,<br>  30060<br>]</pre> | no |
| keypair | n/a | `string` | n/a | yes |
| master\_azs | n/a | `list(string)` | `[]` | no |
| master\_flavors | n/a | `list(string)` | `[]` | no |
| master\_images | n/a | `list(string)` | `[]` | no |
| master\_names | It can be used to uniquely identify masters | `list(string)` | `[]` | no |
| master\_root\_disk\_sizes | If 'create\_root\_disk\_on\_volume=true' and the master flavor does not specify a disk size, the root disk volume of this particular instance will have this size. | `list(number)` | `[]` | no |
| master\_root\_disk\_volume\_types | If 'create\_root\_disk\_on\_volume=true', volume type for root disk of this particular control plane node. If 'root\_disk\_volume\_type' is left empty, default volume type of your IaaS environment is used. | `list(string)` | `[]` | no |
| masters | n/a | `number` | `3` | no |
| monitoring\_manage\_thanos\_bucket | Create an object storage container for thanos. | `bool` | `false` | no |
| network\_mtu | MTU for the network used for the cluster. | `number` | `1450` | no |
| public\_network | n/a | `string` | `"shared-public-IPv4"` | no |
| root\_disk\_volume\_type | If 'create\_root\_disk\_on\_volume=true', the volume type to be used as default for all instances. If left empty, default of IaaS environment is used. | `string` | `""` | no |
| ssh\_cidrs | n/a | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| subnet\_cidr | n/a | `string` | `"172.30.154.0/24"` | no |
| subnet\_v6\_cidr | n/a | `string` | `"fd00::/120"` | no |
| thanos\_delete\_container | n/a | `bool` | `false` | no |
| timeout\_time | n/a | `string` | `"30m"` | no |
| worker\_anti\_affinity\_group\_name | n/a | `string` | `"cah-anti-affinity"` | no |
| worker\_azs | n/a | `list(string)` | `[]` | no |
| worker\_flavors | n/a | `list(string)` | `[]` | no |
| worker\_images | n/a | `list(string)` | `[]` | no |
| worker\_join\_anti\_affinity\_group | n/a | `list(bool)` | `[]` | no |
| worker\_names | It can be used to uniquely identify workers | `list(string)` | `[]` | no |
| worker\_root\_disk\_sizes | If 'create\_root\_disk\_on\_volume=true', volume type for root disk of this particular worker node. If 'root\_disk\_volume\_type' is left empty, default volume type of your IaaS environment is used. | `list(number)` | `[]` | no |
| worker\_root\_disk\_volume\_types | If 'create\_root\_disk\_on\_volume=true', volume types of easdasd TODO | `list(string)` | `[]` | no |
| workers | n/a | `number` | `4` | no |

# Outputs

No outputs.
