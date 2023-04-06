# yk8s-Cluster Configuration

The [environment variables](./environmental-variables.md) affect the [action scripts](./../operation/actions-references.md). The `config/config.toml` however is the main configuration file and can be adjusted to customize the yk8s cluster to fit your needs. It also contains operational flags which can trigger operational tasks. After [initializing a cluster repository](./initialization.md), the `config/config.toml` contains necessary (default) values to create a cluster. However, you'll still need to adjust some of them before triggering a cluster creation.

## The `config/config.toml` configuration file

The `config.toml` configuration file is created during the [cluster repository initialization](./../usage/initialization.md) from the `templates/config.template.toml` file.
You can (and must) adjust some of it's values.

Before triggering an action script, the [inventory updater](./../operation/actions-references.md#update_inventorypy) automatically reads the configuration file, processes it,
and puts variables into the `inventory/`. The `inventory/` is automatically included. Following the concept of separation of concerns, variables are only
available to stages/layers which need them.

### Configuring Terraform

You can overwrite all Terraform related variables (see below for a complete list) in the Terraform section of your `config.toml`.

By default 3 control plane nodes and 4 workers will get created.
You'll need to adjust these values if you e.g. want to enable [rook](./../managed-services/rook/overview.md).

Note: Right now there is a variable `masters` to configure the k8s controller server count and `workers` for the k8s node count. However there is no explicit variable for the gateway node count! This is implicitly defined by the number of elements in the `azs` array.

Please not that with the introduction of `for_each` in our terraform module, you can delete individual nodes. Consider the following example:

```
[terraform]
workers = 3
worker_names = ["0", "1", "2"]
```

In order to delete any of the nodes, decrease the `workers` count and remove the suffix of the worker from the list. After removing, i.e., "1", your config would look like this:

```
[terraform]
workers = 2
worker_names = ["0", "2"]
```

For an auto-generated complete list of variables,
please refer to [Appendix A](#appendix-a-terraform-docs).

Excerpt from `templates/config.template-toml`:

<details>
<summary>config.toml: Terraform configuration</summary>

```toml
{{#include ../templates/config.template.toml:terraform_config}}
```
</details>

### Configuring Load-Balancing

By default, if you're deploying on top of OpenStack, the self-developed load-balancing solution [ch-k8s-lbaas](./../managed-services/load-balancing/ch-k8s-lbaas.md)
will be used to avoid the aches of using OpenStack Octavia.
Nonetheless, you are not forced to use it and can easily disable it.

The following section contains legacy load-balancing options which will probably be removed in the foreseeable future.

<details>
<summary>config.toml: Historic load-balancing configuration</summary>

```toml
{{#include ../templates/config.template.toml:load-balancing_config}}
```
</details>

### Kubernetes Cluster Configuration

This section contains generic information about the Kubernetes cluster configuration.
#### Basic Cluster Configuration

<details>
<summary>config.toml: Kubernetes basic cluster configuration</summary>

```toml
{{#include ../templates/config.template.toml:kubernetes_basic_cluster_configuration}}
```
</details>

#### Calico Configuration

The following configuration options are specific to calico, our CNI plugin in use.

<details>
<summary>config.toml: Kubernetes basic cluster configuration</summary>

```toml
{{#include ../templates/config.template.toml:calico_configuration}}
```

#### Storage Configuration

<details>
<summary>config.toml: Kubernetes - Basic Storage Configuration</summary>

```toml
{{#include ../templates/config.template.toml:storage_base_configuration}}
```
</details>

<details>
<summary>config.toml: Kubernetes - Static Local Storage Configuration</summary>

```toml
{{#include ../templates/config.template.toml:storage_local_static_configuration}}
```
</details>

<details>
<summary>config.toml: Kubernetes - Dynamic Local Storage Configuration</summary>

```toml
{{#include ../templates/config.template.toml:storage_local_dynamic_configuration}}
```
</details>

#### Monitoring Configuration

<details>
<summary>config.toml: Kubernetes - Monitoring Configuration</summary>

```toml
{{#include ../templates/config.template.toml:kubernetes_monitoring_configuration}}
```
</details>

#### Global Monitoring Configuration

It is possible to connect the monitoring stack of your yk8s-cluster to an external endpoint like e.g.
a monitoring-cluster. The following section can be used to enable and configure that.

> ***Note:*** This requires changes and therefore the (re-)appliance of all layers.

<details>
<summary>config.toml: Kubernetes - Global Monitoring Configuration</summary>

```toml
{{#include ../templates/config.template.toml:kubernetes_global_monitoring_configuration}}
```
</details>

#### Network Configuration

> ***Note:*** To enable the calico network plugin, `kubernetes.network.plugin` needs to be set to `calico`.

<details>
<summary>config.toml: Kubernetes - Network Configuration</summary>

```toml
{{#include ../templates/config.template.toml:kubernetes_network_configuration}}
```
</details>

#### kubelet Configuration

The LCM supports the customization of certain variables of `kubelet` for (meta-)worker nodes.

> ***Note:*** Applying changes requires to enable [disruptive actions](./environmental-variables.md#behavior-altering-variables).

<details>
<summary>config.toml: Kubernetes - kubelet Configuration</summary>

```toml
{{#include ../templates/config.template.toml:kubernetes_kubelet_configuration}}
```
</details>

#### Continuous Join Key Configuration

Currently, this is only needed for yk8s clusters created via the yaook/metal-controller on bare metal.

<details>
<summary>config.toml: Kubernetes - Continuous Join Key Configuration</summary>

```toml
{{#include ../templates/config.template.toml:kubernetes_continuous_join_key_configuration}}
```
</details>

### KSL - Kubernetes Service Layer

#### Rook Configuration

The used rook setup is explained in more detail [here](./../managed-services/rook/overview.md).

> ***Note:*** To enable rook in a cluster on top of OpenStack, you need to set both `k8s-service-layer.rook.nosds` and `k8s-service-layer.rook.osd_volume_size`, as well as enable [`kubernetes.storage.rook_enabled` and either `kubernetes.local_storage.dynamic.enabled` or `kubernetes.local_storage.static.enabled` local storage](#storage-configuration) (or both).

<details>
<summary>config.toml: KSL - Rook Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ksl_rook_configuration}}
```
</details>

#### Prometheus-based Monitoring Configuration

The used prometheus-based monitoring setup will be explained in more detail soon :)

> ***Note:*** To enable prometheus, `k8s-serice-layer.prometheus.install` and `kubernetes.monitoring.enabled` need to be set to `true`.

<details>
<summary>config.toml: KSL - Prometheus Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ksl_prometheus_configuration}}
```
</details>

#### NGINX Ingress Controller Configuration

The used NGINX ingress controller setup will be explained in more detail soon :)

> ***Note:*** To enable an ingress controller, `k8s-service-layer.ingress.enabled` needs to be set to `true`.

<details>
<summary>config.toml: KSL - NGINX Ingress Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ksl_ingress_configuration}}
```
</details>

#### Cert-Manager Configuration

The used Cert-Manager controller setup will be explained in more detail soon :)

> ***Note:*** To enable cert-manager, `k8s-service-layer.cert-manager.enabled` needs to be set to `true`.
<details>
<summary>config.toml: KSL - Cert-Manager Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ksl_cert_manager_configuration}}
```
</details>

#### etcd-backup Configuration

Automated etcd backups can be configured in this section.
When enabled it periodically creates snapshots of etcd database and store it in a object storage using s3.
It uses the helm chart [etcdbackup](https://gitlab.com/yaook/operator/-/tree/devel/yaook/helm_builder/Charts/etcd-backup) present in yaook operator helm chart repository.
The object storage retains data for 30 days then deletes it.

The usage of it is disabled by default but can be enabled (and configured) in the following section.
The s3 config yaml file name **MUST** be set when etcd backups are enabled.
The file should be kept under `config/` dir and should be protected.

> ***Note:*** To enable etcd-backup, `k8s-service-layer.etcd-backup.enabled` needs to be set to `true`.
<details>
<summary>config.toml: KSL - Etcd-backup Configuration</summary>

```toml
{{#include ../templates/config.template.toml:etcd_backup_configuration}}
```
</details>

The following values need to be set:

| Variable         | Description                           |
| :--------------- | :------------------------------------ |
| `access_key`     | `Identifier for your S3 endpoint`     |
| `secret_key`     | `Credential for your S3 endpoint`     |
| `endpoint_url`   | `URL of your S3 endpoint`             |
| `endpoint_cacrt` | `Certificate bundle of the endpoint.` |

<details>
<summary> etcd-backup configuration template</summary>

```yaml
{{#include ../templates/etcd_backup_s3_config.template.yaml}}
```
</details>

<details>
<summary>Generate/Figure out etcd-backup configuration values</summary>

```
# Generate access and secret key on OpenStack
openstack ec2 credentials create

# Get certificate bundle of url
openssl s_client -connect ENDPOINT_URL:PORT -showcerts 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p'
```
</details>

### Node-Scheduling: Labels and Taints Configuration

More details about the labels and taints configuration can be found [here](./../operation/node-scheduling.md).

<details>
<summary>config.toml: KSL - Node-Scheduling: Labels and Taints Configuration</summary>

```toml
{{#include ../templates/config.template.toml:node_scheduling_configuration}}
```
</details>

### Wireguard Configuration

You **MUST** add yourself to the [wireguard](./../vpn/wireguard.md) peers.

You can do so either in the following section of the config file or
by using and configuring a git submodule.
This submodule would then refer to another repository, holding
the wireguard public keys of everybody that should have access to
the cluster by default. This is the recommended approach for
companies and organizations.

<details>
<summary>config.toml: Wireguard Configuration</summary>

```toml
{{#include ../templates/config.template.toml:wireguard_config}}
```
</details>

### IPsec Configuration

More details about the IPsec setup can be found [here](./../vpn/ipsec.md).

<details>
<summary>config.toml: IPsec Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ipsec_configuration}}
```
</details>

### Passwordstore Configuration

You **MUST** add yourself to the passwordstore users.

You can do so either by adding yourself to
`passwordstore.additional_users` in the config file below or
by using and configuring a git submodule.
This submodule would then refer to another repository, holding
the GPG IDs of everybody that should have access to the cluster
by default. This is the recommended approach for companies and
organizations.

<details>
<summary>config.toml: Passwordstore Configuration</summary>

```toml
{{#include ../templates/config.template.toml:passwordstore_configuration}}
```
</details>

### Cloud&Heat: ch-role-users Configuration

This section refers to the configuration of the `ch-role-users` git submodule which is an
internally used repository of Cloud&Heat. The usage of it is disabled by default but can be
enabled (and configured) in the following section or via an [environment variable](./../usage/environmental-variables.md#ssh-configuration).

<details>
<summary>config.toml: ch-role-users Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ch-role-users_configuration}}
```
</details>

### Testing

#### Testing Nodes

The following configuration section can be used to ensure that smoke tests and checks are executed
from different nodes. This is disabled by default as it requires some prethinking.

<details>
<summary>config.toml: Testing Nodes Configuration</summary>

```toml
{{#include ../templates/config.template.toml:testing_test_nodes_configuration}}
```
</details>

## Custom Configuration

Since yaook/k8s allows to [execute custom playbook(s)](./../design/abstraction-layers.md#customization),
the following section allows you to specify your own custom variables to be used in these.

<details>
<summary>config.toml: Custom Configuration</summary>

```toml
{{#include ../templates/config.template.toml:custom_configuration}}
```
</details>

## Miscellaneous Configuration

This section contains various configuration options for special use cases.
You won't need to enable and adjust any of these under normal circumstances.

<details>
<summary>Miscellaneous configuration</summary>

```toml
{{#include ../templates/config.template.toml:miscellaneous_configuration}}
```
</details>

## Ansible Configuration

The Ansible configuration file can be found in the `ansible/` directory.
It is used across all stages and layers.

<details>
<summary>Default Ansible configuration</summary>

```ini
{{#include ../templates/ansible.cfg}}
```
</details>

---

## Appendix A: terraform-docs

The following section has been generated by [`terraform-docs`](https://github.com/terraform-docs/terraform-docs)
via:

```
terraform-docs markdown table terraform
```

and should be kept up to date on a regular base.

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.2.3 |
| <a name="provider_openstack"></a> [openstack](#provider\_openstack) | 1.48.0 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

### Modules

No modules.

### Resources

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

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azs"></a> [azs](#input\_azs) | If 'enable\_az\_management=true' defines which availability zones of your cloud to use to distribute the spawned server for better HA. Additionally the count of the array will define how many gateway server will be spawned. The naming of the elements doesn't matter if 'enable\_az\_management=false'. It is also used for unique naming of gateways. | `list(string)` | <pre>[<br>  "AZ1",<br>  "AZ2",<br>  "AZ3"<br>]</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | n/a | `string` | `"managed-k8s"` | no |
| <a name="input_create_root_disk_on_volume"></a> [create\_root\_disk\_on\_volume](#input\_create\_root\_disk\_on\_volume) | n/a | `bool` | `false` | no |
| <a name="input_default_master_flavor"></a> [default\_master\_flavor](#input\_default\_master\_flavor) | n/a | `string` | `"M"` | no |
| <a name="input_default_master_image_name"></a> [default\_master\_image\_name](#input\_default\_master\_image\_name) | n/a | `string` | `"Ubuntu 20.04 LTS x64"` | no |
| <a name="input_default_master_root_disk_size"></a> [default\_master\_root\_disk\_size](#input\_default\_master\_root\_disk\_size) | If 'create\_root\_disk\_on\_volume=true', the master flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size. | `number` | `50` | no |
| <a name="input_default_worker_flavor"></a> [default\_worker\_flavor](#input\_default\_worker\_flavor) | n/a | `string` | `"M"` | no |
| <a name="input_default_worker_image_name"></a> [default\_worker\_image\_name](#input\_default\_worker\_image\_name) | n/a | `string` | `"Ubuntu 20.04 LTS x64"` | no |
| <a name="input_default_worker_root_disk_size"></a> [default\_worker\_root\_disk\_size](#input\_default\_worker\_root\_disk\_size) | If 'create\_root\_disk\_on\_volume=true', the worker flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size. | `number` | `50` | no |
| <a name="input_dualstack_support"></a> [dualstack\_support](#input\_dualstack\_support) | If set to true, dualstack support related resources will be (re-)created | `bool` | n/a | yes |
| <a name="input_enable_az_management"></a> [enable\_az\_management](#input\_enable\_az\_management) | If set to false, the availability zone of instances will not be managed. This is useful in CI environments if the Cloud Is Full. | `bool` | `true` | no |
| <a name="input_gateway_flavor"></a> [gateway\_flavor](#input\_gateway\_flavor) | n/a | `string` | `"XS"` | no |
| <a name="input_gateway_image_name"></a> [gateway\_image\_name](#input\_gateway\_image\_name) | n/a | `string` | `"Debian 11 (bullseye)"` | no |
| <a name="input_gateway_root_disk_volume_size"></a> [gateway\_root\_disk\_volume\_size](#input\_gateway\_root\_disk\_volume\_size) | If 'create\_root\_disk\_on\_volume=true' and the gateway flavor does not specify a disk size, the root disk volume will have this size. | `number` | `10` | no |
| <a name="input_gateway_root_disk_volume_type"></a> [gateway\_root\_disk\_volume\_type](#input\_gateway\_root\_disk\_volume\_type) | If 'create\_root\_disk\_on\_volume=true', set the volume type of the root disk volume for Gateways. Can't be configured separately for each instance | `string` | `""` | no |
| <a name="input_haproxy_ports"></a> [haproxy\_ports](#input\_haproxy\_ports) | n/a | `list(number)` | <pre>[<br>  30000,<br>  30060<br>]</pre> | no |
| <a name="input_keypair"></a> [keypair](#input\_keypair) | n/a | `string` | n/a | yes |
| <a name="input_master_azs"></a> [master\_azs](#input\_master\_azs) | n/a | `list(string)` | `[]` | no |
| <a name="input_master_flavors"></a> [master\_flavors](#input\_master\_flavors) | n/a | `list(string)` | `[]` | no |
| <a name="input_master_images"></a> [master\_images](#input\_master\_images) | n/a | `list(string)` | `[]` | no |
| <a name="input_master_names"></a> [master\_names](#input\_master\_names) | It can be used to uniquely identify masters | `list(string)` | `[]` | no |
| <a name="input_master_root_disk_sizes"></a> [master\_root\_disk\_sizes](#input\_master\_root\_disk\_sizes) | If 'create\_root\_disk\_on\_volume=true' and the master flavor does not specify a disk size, the root disk volume of this particular instance will have this size. | `list(number)` | `[]` | no |
| <a name="input_master_root_disk_volume_types"></a> [master\_root\_disk\_volume\_types](#input\_master\_root\_disk\_volume\_types) | If 'create\_root\_disk\_on\_volume=true', volume type for root disk of this particular control plane node. If 'root\_disk\_volume\_type' is left empty, default volume type of your IaaS environment is used. | `list(string)` | `[]` | no |
| <a name="input_masters"></a> [masters](#input\_masters) | n/a | `number` | `3` | no |
| <a name="input_monitoring_manage_thanos_bucket"></a> [monitoring\_manage\_thanos\_bucket](#input\_monitoring\_manage\_thanos\_bucket) | Create an object storage container for thanos. | `bool` | `false` | no |
| <a name="input_network_mtu"></a> [network\_mtu](#input\_network\_mtu) | MTU for the network used for the cluster. | `number` | `1450` | no |
| <a name="input_public_network"></a> [public\_network](#input\_public\_network) | n/a | `string` | `"shared-public-IPv4"` | no |
| <a name="input_root_disk_volume_type"></a> [root\_disk\_volume\_type](#input\_root\_disk\_volume\_type) | If 'create\_root\_disk\_on\_volume=true', the volume type to be used as default for all instances. If left empty, default of IaaS environment is used. | `string` | `""` | no |
| <a name="input_ssh_cidrs"></a> [ssh\_cidrs](#input\_ssh\_cidrs) | n/a | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | n/a | `string` | `"172.30.154.0/24"` | no |
| <a name="input_subnet_v6_cidr"></a> [subnet\_v6\_cidr](#input\_subnet\_v6\_cidr) | n/a | `string` | `"fd00::/120"` | no |
| <a name="input_thanos_delete_container"></a> [thanos\_delete\_container](#input\_thanos\_delete\_container) | n/a | `bool` | `false` | no |
| <a name="input_timeout_time"></a> [timeout\_time](#input\_timeout\_time) | n/a | `string` | `"30m"` | no |
| <a name="input_worker_anti_affinity_group_name"></a> [worker\_anti\_affinity\_group\_name](#input\_worker\_anti\_affinity\_group\_name) | n/a | `string` | `"cah-anti-affinity"` | no |
| <a name="input_worker_azs"></a> [worker\_azs](#input\_worker\_azs) | n/a | `list(string)` | `[]` | no |
| <a name="input_worker_flavors"></a> [worker\_flavors](#input\_worker\_flavors) | n/a | `list(string)` | `[]` | no |
| <a name="input_worker_images"></a> [worker\_images](#input\_worker\_images) | n/a | `list(string)` | `[]` | no |
| <a name="input_worker_join_anti_affinity_group"></a> [worker\_join\_anti\_affinity\_group](#input\_worker\_join\_anti\_affinity\_group) | n/a | `list(bool)` | `[]` | no |
| <a name="input_worker_names"></a> [worker\_names](#input\_worker\_names) | It can be used to uniquely identify workers | `list(string)` | `[]` | no |
| <a name="input_worker_root_disk_sizes"></a> [worker\_root\_disk\_sizes](#input\_worker\_root\_disk\_sizes) | If 'create\_root\_disk\_on\_volume=true', volume type for root disk of this particular worker node. If 'root\_disk\_volume\_type' is left empty, default volume type of your IaaS environment is used. | `list(number)` | `[]` | no |
| <a name="input_worker_root_disk_volume_types"></a> [worker\_root\_disk\_volume\_types](#input\_worker\_root\_disk\_volume\_types) | If 'create\_root\_disk\_on\_volume=true', volume types of easdasd TODO | `list(string)` | `[]` | no |
| <a name="input_workers"></a> [workers](#input\_workers) | n/a | `number` | `4` | no |
