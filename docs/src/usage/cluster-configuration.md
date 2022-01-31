# yk8s-Cluster configuration

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

<details>
<summary>All Terraform variables and their defaults</summary>

```
{{#include ../templates/terraform_variables.tf:terraform_variables}}
```
</details>

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

If you want to use rook, you additionally need to enable either [dynamic or static local storage](#storage-configuration) (or both).

The following variables must be defined when deploying rook:

* `rook_nosds`
* `osd_volume_size`

<details>
<summary>config.toml: KSL - Rook Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ksl_rook_configuration}}
```
</details>

#### Prometheus-based Monitoring Configuration

The used prometheus-based monitoring setup will be explained in more detail soon :)

<details>
<summary>config.toml: KSL - Prometheus Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ksl_prometheus_configuration}}
```
</details>

#### NGINX Ingress Controller Configuration

The used NGINX ingress controller setup will be explained in more detail soon :)

<details>
<summary>config.toml: KSL - Prometheus Configuration</summary>

```toml
{{#include ../templates/config.template.toml:ksl_ingress_configuration}}
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

You **MUST** add yourself to the wireguard peers. You can do so either in the following section of the config file or
by using and configuring a wireguard users git repository. E.g. you may stumble across the term `wg_user`.
That is a git submodule which refers to an internal C&H repository which holds the WireGuard public keys of all Cloud&heat members
which should have access to clusters by default.

More details about the wireguard setup can be found [here](./../vpn/wireguard.md).

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

You **MUST** add yourself to the passwordstore users. You can do so either in the following section of the config file or
by using and configuring a passwordstore users git repository. E.g., you may stumble across the term `passwordstore_users`.
That is a git submodule which refers to an internal C&H repository which holds the GPG ids of all Cloud&Heat members
which should have access to clusters by default.

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

## Ansible Configuration

The Ansible configuration file can be found in the `ansible/` directory.
It is used across all stages and layers.

<details>
<summary>Default Ansible configuration</summary>

```ini
{{#include ../templates/ansible.cfg}}
```
</details>