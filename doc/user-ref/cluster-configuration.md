# Configuration Reference

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

<details>
<summary>All Terraform variables and their defaults</summary>

```{literalinclude} ../templates/terraform_variables.tf
---
start-after: "# ANCHOR: terraform_variables"
end-before: "# ANCHOR_END: terraform_variables"
language: terraform
---
```
</details>

<details>
<summary>config.toml: Terraform configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: terraform_config"
end-before: "# ANCHOR_END: terraform_config"
language: toml
---
```
</details>

### Configuring Load-Balancing

By default, if you're deploying on top of OpenStack, the self-developed load-balancing solution [ch-k8s-lbaas](./../managed-services/load-balancing/ch-k8s-lbaas.md)
will be used to avoid the aches of using OpenStack Octavia.
Nonetheless, you are not forced to use it and can easily disable it.

The following section contains legacy load-balancing options which will probably be removed in the foreseeable future.

<details>
<summary>config.toml: Historic load-balancing configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: load-balancing_config"
end-before: "# ANCHOR_END: load-balancing_config"
language: toml
---
```
</details>

### Kubernetes Cluster Configuration

This section contains generic information about the Kubernetes cluster configuration.
#### Basic Cluster Configuration

<details>
<summary>config.toml: Kubernetes basic cluster configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: kubernetes_basic_cluster_configuration"
end-before: "# ANCHOR_END: kubernetes_basic_cluster_configuration"
language: toml
---
```
</details>

#### Storage Configuration

<details>
<summary>config.toml: Kubernetes - Basic Storage Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: storage_base_configuration"
end-before: "# ANCHOR_END: storage_base_configuration"
language: toml
---
```
</details>

<details>
<summary>config.toml: Kubernetes - Static Local Storage Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: storage_local_static_configuration"
end-before: "# ANCHOR_END: storage_local_static_configuration"
language: toml
---
```
</details>

<details>
<summary>config.toml: Kubernetes - Dynamic Local Storage Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: storage_local_dynamic_configuration"
end-before: "# ANCHOR_END: storage_local_dynamic_configuration"
language: toml
---
```
</details>

#### Monitoring Configuration

<details>
<summary>config.toml: Kubernetes - Monitoring Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: kubernetes_monitoring_configuration"
end-before: "# ANCHOR_END: kubernetes_monitoring_configuration"
language: toml
---
```
</details>

#### Global Monitoring Configuration

It is possible to connect the monitoring stack of your yk8s-cluster to an external endpoint like e.g.
a monitoring-cluster. The following section can be used to enable and configure that.

```{Note}
This requires changes and therefore the (re-)appliance of all layers.
````

<details>
<summary>config.toml: Kubernetes - Global Monitoring Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: kubernetes_global_monitoring_configuration"
end-before: "# ANCHOR_END: kubernetes_global_monitoring_configuration"
language: toml
---
```
</details>

#### Network Configuration

```{Note}
To enable the calico network plugin, `kubernetes.network.plugin` needs to be set to `calico`.
````

<details>
<summary>config.toml: Kubernetes - Network Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: kubernetes_network_configuration"
end-before: "# ANCHOR_END: kubernetes_network_configuration"
language: toml
---
```
</details>

#### kubelet Configuration

The LCM supports the customization of certain variables of `kubelet` for (meta-)worker nodes.

```{Note}
Applying changes requires to enable [disruptive actions](./environmental-variables.md#behavior-altering-variables).
````

<details>
<summary>config.toml: Kubernetes - kubelet Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: kubernetes_kubelet_configuration"
end-before: "# ANCHOR_END: kubernetes_kubelet_configuration"
language: toml
---
```
</details>

#### Continuous Join Key Configuration

Currently, this is only needed for yk8s clusters created via the yaook/metal-controller on bare metal.

<details>
<summary>config.toml: Kubernetes - Continuous Join Key Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: kubernetes_continuous_join_key_configuration"
end-before: "# ANCHOR_END: kubernetes_continuous_join_key_configuration"
language: toml
---
```
</details>

### KSL - Kubernetes Service Layer

#### Rook Configuration

The used rook setup is explained in more detail [here](./../managed-services/rook/overview.md).

```{Note}
To enable rook in a cluster on top of OpenStack, you need to set both `k8s-service-layer.rook.nosds` and `k8s-service-layer.rook.osd_volume_size`, as well as enable [`kubernetes.storage.rook_enabled` and either `kubernetes.local_storage.dynamic.enabled` or `kubernetes.local_storage.static.enabled` local storage](#storage-configuration) (or both).
````

<details>
<summary>config.toml: KSL - Rook Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: ksl_rook_configuration"
end-before: "# ANCHOR_END: ksl_rook_configuration"
language: toml
---
```
</details>

#### Prometheus-based Monitoring Configuration

The used prometheus-based monitoring setup will be explained in more detail soon :)

```{Note}
To enable prometheus, `k8s-serice-layer.prometheus.install` and `kubernetes.monitoring.enabled` need to be set to `true`.
````

<details>
<summary>config.toml: KSL - Prometheus Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: ksl_prometheus_configuration"
end-before: "# ANCHOR_END: ksl_prometheus_configuration"
language: toml
---
```
</details>

#### NGINX Ingress Controller Configuration

The used NGINX ingress controller setup will be explained in more detail soon :)

```{Note}
To enable an ingress controller, `k8s-service-layer.ingress.enabled` needs to be set to `true`.
````

<details>
<summary>config.toml: KSL - NGINX Ingress Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: ksl_ingress_configuration"
end-before: "# ANCHOR_END: ksl_ingress_configuration"
language: toml
---
```
</details>

#### Cert-Manager Configuration

The used Cert-Manager controller setup will be explained in more detail soon :)

```{Note}
To enable cert-manager, `k8s-service-layer.cert-manager.enabled` needs to be set to `true`.
````
<details>
<summary>config.toml: KSL - Cert-Manager Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: ksl_cert_manager_configuration"
end-before: "# ANCHOR_END: ksl_cert_manager_configuration"
language: toml
---
```
</details>

#### Etcd-backup Configuration

Automated etcd backups can be configured in this section. When enabled it periodically creates snapshots of etcd database and store it in a object storage using s3. It uses the helm chart [etcdbackup](https://gitlab.com/yaook/operator/-/tree/devel/yaook/helm_builder/Charts/etcd-backup) present in yaook operator helm chart repository. The object storage retains data for 30 days then deletes it.

The usage of it is disabled by default but can be enabled (and configured) in the following section. The s3 config yaml file name **Must** be set when etcd backups are enabled. The file should be kept under `config/` dir and should be protected.

```{Note}
To enable etcd-backup, `k8s-service-layer.etcd-backup.enabled` needs to be set to `true`.
````
<details>
<summary>config.toml: KSL - Etcd-backup Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: etcd_backup_configuration"
end-before: "# ANCHOR_END: etcd_backup_configuration"
language: toml
---
```
</details>


### Node-Scheduling: Labels and Taints Configuration

More details about the labels and taints configuration can be found [here](./../operation/node-scheduling.md).

<details>
<summary>config.toml: KSL - Node-Scheduling: Labels and Taints Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: node_scheduling_configuration"
end-before: "# ANCHOR_END: node_scheduling_configuration"
language: toml
---
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

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: wireguard_config"
end-before: "# ANCHOR_END: wireguard_config"
language: toml
---
```
</details>

### IPsec Configuration

More details about the IPsec setup can be found [here](./../vpn/ipsec.md).

<details>
<summary>config.toml: IPsec Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: ipsec_configuration"
end-before: "# ANCHOR_END: ipsec_configuration"
language: toml
---
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

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: passwordstore_configuration"
end-before: "# ANCHOR_END: passwordstore_configuration"
language: toml
---
```
</details>

### Cloud&Heat: ch-role-users Configuration

This section refers to the configuration of the `ch-role-users` git submodule which is an
internally used repository of Cloud&Heat. The usage of it is disabled by default but can be
enabled (and configured) in the following section or via an [environment variable](./../usage/environmental-variables.md#ssh-configuration).

<details>
<summary>config.toml: ch-role-users Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: ch-role-users_configuration"
end-before: "# ANCHOR_END: ch-role-users_configuration"
language: toml
---
```
</details>

### Testing

#### Testing Nodes

The following configuration section can be used to ensure that smoke tests and checks are executed
from different nodes. This is disabled by default as it requires some prethinking.

<details>
<summary>config.toml: Testing Nodes Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: testing_test_nodes_configuration"
end-before: "# ANCHOR_END: testing_test_nodes_configuration"
language: toml
---
```
</details>

## Custom Configuration

Since yaook/k8s allows to [execute custom playbook(s)](./../design/abstraction-layers.md#customization),
the following section allows you to specify your own custom variables to be used in these.

<details>
<summary>config.toml: Custom Configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: custom_configuration"
end-before: "# ANCHOR_END: custom_configuration"
language: toml
---
```
</details>

## Miscellaneous Configuration

This section contains various configuration options for special use cases.
You won't need to enable and adjust any of these under normal circumstances.

<details>
<summary>Miscellaneous configuration</summary>

```{literalinclude} ../templates/config.template.toml
---
start-after: "# ANCHOR: miscellaneous_configuration"
end-before: "# ANCHOR_END: miscellaneous_configuration"
language: toml
---
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
