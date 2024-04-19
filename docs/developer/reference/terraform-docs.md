<!-- BEGIN_TF_DOCS -->
# Terraform

The following is automatically generated reference
documentation for Terraform by [terraform-docs](https://terraform-docs.io/).

It can be generated via

```console
$ terraform-docs -c docs/.terraform-docs.yaml terraform
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| local | >= 2.4.0 |
| openstack | ~> 2.1.0 |
| template | >= 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| local | 2.5.1 |
| openstack | 2.1.0 |
| template | 2.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.final_group_all](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.final_networking](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.inventory_yaook-k8s](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.trampoline_gateways](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [openstack_blockstorage_volume_v3.gateway-volume](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/blockstorage_volume_v3) | resource |
| [openstack_blockstorage_volume_v3.master-volume](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/blockstorage_volume_v3) | resource |
| [openstack_blockstorage_volume_v3.worker-volume](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/blockstorage_volume_v3) | resource |
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azs | If 'enable\_az\_management=true' defines which availability zones of your cloud to use to distribute the spawned server for better HA. Additionally the count of the array will define how many gateway server will be spawned. The naming of the elements doesn't matter if 'enable\_az\_management=false'. It is also used for unique naming of gateways. | `set(string)` | <pre>[<br>  "AZ1",<br>  "AZ2",<br>  "AZ3"<br>]</pre> | no |
| cluster\_name | n/a | `string` | `"managed-k8s"` | no |
| create\_root\_disk\_on\_volume | n/a | `bool` | `false` | no |
| default\_master\_flavor | n/a | `string` | `"M"` | no |
| default\_master\_image\_name | n/a | `string` | `"Ubuntu 22.04 LTS x64"` | no |
| default\_master\_root\_disk\_size | If 'create\_root\_disk\_on\_volume=true', the master flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size. | `number` | `50` | no |
| default\_worker\_flavor | n/a | `string` | `"M"` | no |
| default\_worker\_image\_name | n/a | `string` | `"Ubuntu 22.04 LTS x64"` | no |
| default\_worker\_root\_disk\_size | If 'create\_root\_disk\_on\_volume=true', the worker flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size. | `number` | `50` | no |
| dns\_nameservers\_v4 | A list of IPv4 addresses which will be configured as DNS nameservers of the IPv4 subnet. | `list(string)` | `[]` | no |
| enable\_az\_management | If set to false, the availability zone of instances will not be managed. This is useful in CI environments if the Cloud Is Full. | `bool` | `true` | no |
| gateway\_flavor | n/a | `string` | `"XS"` | no |
| gateway\_image\_name | n/a | `string` | `"Debian 12 (bookworm)"` | no |
| gateway\_root\_disk\_volume\_size | If 'create\_root\_disk\_on\_volume=true' and the gateway flavor does not specify a disk size, the root disk volume will have this size. | `number` | `10` | no |
| gateway\_root\_disk\_volume\_type | If 'create\_root\_disk\_on\_volume=true', set the volume type of the root disk volume for Gateways. Can't be configured separately for each instance. If left empty, the volume type specified in 'root\_disk\_volume\_type' will be used. | `string` | `""` | no |
| gitlab\_backend | If set to true, GitLab will be used as Terraform HTTP backend. | `bool` | `false` | no |
| gitlab\_base\_url | Base URL of GitLab for Terraform HTTP backend if 'gitlab\_backend=true'. | `string` | `""` | no |
| gitlab\_project\_id | If 'gitlab\_backend=true', the Terraform state will be stored in the GitLab repo with this ID. | `string` | `""` | no |
| gitlab\_state\_name | If 'gitlab\_backend=true', the terraform state file will have this name. | `string` | `""` | no |
| ipv4\_enabled | If set to true, ipv4 will be used | `bool` | `true` | no |
| ipv6\_enabled | If set to true, ipv6 will be used | `bool` | `false` | no |
| keypair | n/a | `string` | n/a | yes |
| masters | User defined list of control plane nodes to be created with specified values | <pre>map(<br>    object({<br>      image                    = optional(string)<br>      flavor                   = optional(string)<br>      az                       = optional(string) # default: auto-select<br>      root_disk_size           = optional(number)<br>      root_disk_volume_type    = optional(string)<br>    })<br>  )</pre> | <pre>{<br>  "0": {},<br>  "1": {},<br>  "2": {}<br>}</pre> | no |
| monitoring\_manage\_thanos\_bucket | Create an object storage container for thanos. | `bool` | `false` | no |
| network\_mtu | MTU for the network used for the cluster. | `number` | `1450` | no |
| public\_network | n/a | `string` | `"shared-public-IPv4"` | no |
| root\_disk\_volume\_type | If 'create\_root\_disk\_on\_volume=true', the volume type to be used as default for all instances. If left empty, default of IaaS environment is used. | `string` | `""` | no |
| subnet\_cidr | n/a | `string` | `"172.30.154.0/24"` | no |
| subnet\_v6\_cidr | n/a | `string` | `"fd00::/120"` | no |
| thanos\_delete\_container | n/a | `bool` | `false` | no |
| timeout\_time | n/a | `string` | `"30m"` | no |
| worker\_anti\_affinity\_group\_name | n/a | `string` | `"cah-anti-affinity"` | no |
| workers | User defined list of worker nodes to be created with specified values | <pre>map(<br>    object({<br>      image                    = optional(string)<br>      flavor                   = optional(string)<br>      az                       = optional(string) # default: auto-select<br>      root_disk_size           = optional(number)<br>      root_disk_volume_type    = optional(string)<br>      join_anti_affinity_group = optional(bool)<br>    })<br>  )</pre> | <pre>{<br>  "0": {},<br>  "1": {},<br>  "2": {},<br>  "3": {}<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
