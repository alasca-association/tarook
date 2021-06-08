# DualStack-Support on Kubernetes with Calico

Associated [Merge Request](https://gitlab.cloudandheat.com/lcm/managed-k8s/-/merge_requests/176)

---
**NOTE**

It is still possible to create an IPv4-only cluster.

It is currently not possible to create an IPv6-only cluster.

It is **not possible to upgrade** a single stack cluster to a dualStack cluster.

---

## Motivation

IPv4/IPv6 DualStack support enables the allocation of both IPv4 and IPv6 addresses to [Pods](https://kubernetes.io/docs/concepts/workloads/pods/) and [Services](https://kubernetes.io/docs/concepts/services-networking/service/).
This enables Pod off-cluster egress routing (e.g. the Internet) via both, IPv4 and IPv6 interfaces.

## Enabling DualStack-Support for managed-k8s

This section states necessary config changes to your mk8s setup to enable DualStack-support.

### Prerequisites

* Terraform `v0.12` or later
* Kubernetes `v1.21` or later
* Calico `v3.11` or later
* [ch-k8s-lbaas](https://github.com/cloudandheat/ch-k8s-lbaas) `v0.3.3` or later

### Necessary changes in your config file

Adjust your `config/config.toml` to meet the following statements:

* set `dualstack-support=true`
  * this variable is used across all stages to adjust setups and resources
* specify `subnet_v6_cidr`
  * this is the IPv6 subnet that will be created via Terraform
  * e.g.:
    * `subnet_v6_cidr = "fd00::/120"`
* specify `wg_ipv6_cidr` as well as `wg_ipv6_gw`
  * this is the IPv6 CIDR for the allowed IP addresses of wireguard as well as the server/gateway IP address
  * e.g.:
    * `wg_ipv6_cidr = "fd01::/120"`
    * `wg_ipv6_gw = "fd01::1/120"`
* you have to choose calico as CNI plugin
  * `k8s_network_plugin = calico`

## Design / Procedure considerations

The following section provides an overview of assumptions, requirements and design decisions for the DualStack support in managed-k8s.

### DualStack-Support in OpenStack

A Kubernetes cluster with DualStack support requires IPv4 and IPv6 connectivity between the cluster nodes.
As we are deploying on top of OpenStack, we need to adjust Terraform to fulfill the prerequisites.

For Pods to be able to connect to the outside world over IPv6, there must be IPv6 connectivity from the cluster nodes to the outside world.
However, f1a does not support IPv6.
Because we need IPv6 connectivity of the cluster nodes, we need to enable DualStack-Support for the underlying OpenStack nodes via Terraform.

[Enabling a DualStack network](https://docs.openstack.org/neutron/latest/admin/config-ipv6.html) in OpenStack requires:

  * creating a subnet with the `ip_version` field set to `6`
  * set attributes of `ipv6_ra_mode` and `ipv6_address_mode`
  * we are using the DHCPv6 Stateful Configuration
    * `ipv6_ra_mode = "dhcpv6-stateful"`
    * `ipv6_address_mode = "dhcpv6-stateful"`
  * creating an IPv6 router interface

### DualStack-Support for mk8s

---
**NOTE**

The IPv6 addresses assigned to a Pod are unique local. Therefore, they are routable inside the network, but **cannot reach the Internet**.

---

Some information about the general DualStack support in Kubernetes:

* Introduced with `v1.16`, but not fully supported yet
* The DualStack feature for the k8s control plane has been fully added in `v1.21`
* `PodStatus.PodIPs` can now hold multiple IP addresses
* `PodStatus.PodIP` (legacy) is required to be the same as `PodStatus.PodIPs[0]`
* Calico routes IPv6 traffic from Pods over the nodes own IPv6 connectivity
* Please also refer to [Dual-stack support with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/dual-stack-support/)

### [Creating a Kubernetes cluster with DualStack-Support](https://kubernetes.io/docs/concepts/services-networking/dual-stack/#enable-ipv4-ipv6-dual-stack)

In managed-k8s, we do initialize the k8s cluster with the help of [`kubeadm`](https://kubernetes.io/docs/reference/setup-tools/kubeadm/) and the corresponding [configuration file](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file).
Using configuration files for `kubeadm` is a hard requirement for the DualStack-support, because some flags are only supported in the config file and mixing CLI flags with the configuration file is not possible.

To configure `kubelet` for the DualStack support, it is necessary to always [pass the `node-ips` as a parameter](https://github.com/kubernetes/kubernetes/pull/95239#).
Otherwise, `kubelet` will only annotate the first matching IP which is usually the IPv4 address.
The node IPs are checked in the `check-dualstack` role.

### Currently not working

#### DualStack support for the k8s control plane

The `controlPlaneEndpoint` either has to be *one* IP address or a domain name.
Because using a domain name would lead to the DNS resolution overhead, we decided to let the control plane be IPv4-only for now.
However, a VIPv6 is created via Terraform and configured in HAProxy such that it can be used to connect to the control plane.

#### IPv6 load-balanced services

This is mainly because f1a does not support IPv6 and it is unclear how  we want to handle/design the IPv6 stack and handle the load-balancing in Yaook.
Please also refer to [Issue #268](https://gitlab.cloudandheat.com/lcm/managed-k8s/-/issues/269) for more information.

### Adjust the Calico CNI for DualStack-Support

It is necessary to adjust the [CNI config](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) so that Calico's IPAM will allocate both IPv4 and IPv6 addresses for each new Pod.

```json
    "ipam": {
        "type": "calico-ipam",
        "assign_ipv4": "true",
        "assign_ipv6": "true"
    }
```

The environment variables for [`calico/node`](https://docs.projectcalico.org/reference/node/configuration) have to be adjusted:
  * `IP6=autodetect`
    * Calico will detect the node's IPv6 address and use this in its BGP IPv6 config
  * `FELIX_IPV6SUPPORT=true`
    * so that Felix knows to program routing and iptables for IPv6 as well as for IPv4

## DualStack-Support and Wireguard

For the DualStack-support for wireguard, `radvd` is needed on the gateways.
Otherwise, when trying to connect to a node over IPv6, the node does not know a route back out of cluster.

A fixed VIPv6 for the (active) wireguard gateway is created via terraform (`wireguard_gw_fixed_ip_v6`).
This VIP is managed by `keepalived` and will be assigned to the gateway with the highest priority.
On the gateways, `radvd` is configured in such a way, that it only sends router advertisements if the host holds the IP that is managed by `keepalived` (the host gateway is in master state).

From this follows, that only the gateway that really knows a way back to the wireguard client propagates the route (sends the router advertisement).
This way, the k8s nodes know the correct route to the currently active gateway.

---
**NOTE**

Because wireguard is active on all gateways, the (backup/secondary) gateways will not import the propagated route advertisement sent by the currently active gateway.
This is because, they think they already have a route to the wireguard subnet.
From this follows, that it is **not possible** to ssh to the secondary gateways **directly**.
You can still connect to them using their public IP addresses or by using the currently active gateway as jumphost.

---
