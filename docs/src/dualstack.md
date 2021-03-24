# DualStack-Support on Kubernetes with Calico

Associated [Merge Request](https://gitlab.cloudandheat.com/lcm/managed-k8s/-/merge_requests/176)

## Motivation

IPv4/IPv6 DualStack support enables the allocation of both IPv4 and IPv6 addresses to [Pods](https://kubernetes.io/docs/concepts/workloads/pods/) and [Services](https://kubernetes.io/docs/concepts/services-networking/service/).
This enables Pod off-cluster egress routing (e.g. the Internet) via both, IPv4 and IPv6 interfaces.

## Enabling DualStack-Support for managed-k8s

### Prerequisites

* Terraform `v0.12` or later
* Kubernetes `v1.21` or later
* Calico `v3.11` or later

### Necessary changes in your config file

Adjust your `config/config.toml` to meet the following statements:

* set `dualstack-support=true`
* specify `subnet_v6_cidr` for the IPv6 subnet that will be created via Terraform
  * e.g.:
    * `subnet_v6_cidr = "fd00::/120"`
* specify `wg_ipv6_cidr` for wireguard as well as `wg_ipv6_gw`
  * e.g.:
    * `wg_ipv6_cidr = "fd00::/122"`
    * `wg_ipv6_gw = "fd00::1/122"`

---
**NOTE**

It is still possible to create an IPv4-only cluster with calico as CNI plugin.

---
## DualStack-Support for OpenStack

A Kubernetes cluster with DualStack support requires IPv4 and IPv6 connectivity between the cluster nodes.

For Pods to be able to connect to the outside world over IPv6, there must be IPv6 connectivity from the cluster nodes to the outside world.
Because we need IPv6 connectivity of the cluster nodes, we need to enable DualStack-Support for the underlying OpenStack nodes via Terraform.

[Enabling a DualStack network](https://docs.openstack.org/neutron/latest/admin/config-ipv6.html) in OpenStack Networking requires:

  * creating a subnet with the `ip_version` field set to `6`
  * set attributes of `ipv6_ra_mode` and `ipv6_address_mode`
  * we are using the DHCPv6 Stateful Configuration
    * `ipv6_ra_mode = "dhcpv6-stateful"`
    * `ipv6_address_mode = "dhcpv6-stateful"`
  * creating an IPv6 router interface

## DualStack-Support for mk8s

**Currently working**:
* DualStack support for Pods and Services

**Currently not working**:
* DualStack support for the k8s control plane
  * refer: https://gitlab.cloudandheat.com/lcm/managed-k8s/-/merge_requests/182

Some information about the DualStack support in Kubernetes:

* Introduced with `v1.16`, but not fully supported yet
* The DualStack feature for the k8s control plane will be fully added sometime after `v1.21`
* `PodStatus.PodIPs` can hold multiple IP addresses
* `PodStatus.PodIP` (legacy) is required to be the same as `PodStatus.PodIPs[0]`
* Calico routes IPv6 traffic from Pods over the nodes own IPv6 connectivity

---
**NOTE**

The IPv6 addresses assigned to a Pod are unique local. Therefore, they are routable inside the network, but **cannot reach the Internet**.
To enable egress connection, masquerading iptables rules on k8s nodes are necessary
That may can be realized with ip-masq-agent.

References:
* [github: ip-masc-agent](https://github.com/kubernetes-sigs/ip-masq-agent)
* [blog post: how to enable ipv6 on kubernetes](https://medium.com/@elfakharany/how-to-enable-ipv6-on-kubernetes-aka-dual-stack-cluster-ac0fe294e4cf)

---

### [Create a Kubernetes cluster with DualStack-Support](https://kubernetes.io/docs/concepts/services-networking/dual-stack/#enable-ipv4-ipv6-dual-stack)

The following points state the necessary parameters to enable the DualStack feature for Kubernetes:

* [`kube-proxy`](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/) needs to run in [IPVS](https://en.wikipedia.org/wiki/IP_Virtual_Server) mode
* enable `IPv6DualStack` feature gate for relevant components
* We are using [`kubeadm`](https://github.com/kubernetes/kubeadm) to init our k8s clusters
  * Currently there is a [Pull Request](https://github.com/kubernetes/website/pull/26675) adding full DualStack support to `kubeadm`
  * `kubeadm` takes care that the `IPv6DualStack` feature gate is enabled
* Manual configuration
  * kube-controller-manager options:
    * `-- feature-gates="IPv6DualStack=true`
    * `--cluster-cidr=<IPv4 CIDR>,<IPv6 CIDR>`
      * we are using the default value for `<IPv6 CIDR>` (kubeadm takes care of that)
    * `--service-cluster-ip-range=<IPv4 CIDR>,<IPv6 CIDR>`
    * `--node-cidr-mask-size-ipv4|--node-cidr-mask-size-ipv6`
  * kubelet options:
    * `--feature-gates="IPv6DualStack=true`
  * kube-proxy options:
    * `--proxy-mode=ipvs`
    * `--cluster-cidrs=<IPv4 CIDR>, <IPv6 CIDR>`
    * `--feature-gates="IPv6Dualstack=true`

In managed-k8s, we do initialize the k8s cluster with the help of [`kubeadm`](https://kubernetes.io/docs/reference/setup-tools/kubeadm/) and the corresponding [configuration file](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file).
However, in its current state (or rather the version we do use) `kubeadm` does not fully support the creation of a DualStack cluster.
There is an [issue in the official GitHub repository of kubeadm](https://github.com/kubernetes/kubeadm/issues/1612) addressing the DualStack support which is about to be merged in the near future.

The DualStack support for Pods and Services with Calico is working, but the k8s control plane is lacking DualStack features, especially when initialized via `kubeadm`.
The `advertiseAddress` option does [not support multiple IPs](https://github.com/kubernetes/kubeadm/issues/1612#issuecomment-773906850).
This feature will be added sometime after v1.21.
The `advertiseAddress` option in the `InitConfiguration` specifies the IP address that the API-server will advertise it is listening on.

Another problem is, that the `controlPlaneEndpoint` has to be either **one** IP address or a DNS name.
For the `kube-apiserver` to listen on an IPv4 and and IPv6 address (VIPs) we would need to adjust our (load balancing) setup to use DNS.
However, it is not recommended to use IP addresses directly anyway.

To have `kubelet` with DualStack support, it is necessary to always [pass the `node-ips` as a parameter](https://github.com/kubernetes/kubernetes/pull/95239#).
The kubeadm configuration template recently added support for this setting.
This feature is supported since `v1.20`, but we are currently are using `v1.18`.

In the currently used `kubeadm` version (`v1.18`) it is not possible to specify two `podSubnet` nor two `serviceSubnet`.
It is not possible to bind more than one address for the `controllerManager` and `scheduler`.

With the release of `v1.21`, DualStack will be **enabled by default** (when initializing a cluster via `kubeadm`).
Enabling the DualStack feature does not mean that you need to use DualStack addressing.
It is possible to deploy a single-stack cluster that has the DualStack networking feature enabled.

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

For the DualStack support for wireguard, `radvd` is needed on the gateways.
Otherwise, when trying to connect to a node over IPv6, the node does not know a route back out of cluster.

A fixed VIPv6 for the (active) wireguard gateway is created via terraform (`wireguard_gw_fixed_ip_v6`).
This VIP is managed by `keepalived` and will be assigned to the gateway with the highest priority.
On the gateways, `radvd` is configured in such a way, that it only sends router advertisements if the host holds the IP that is managed by `keepalived`.

From this follows, that only the gateway that really knows a way back to the wireguard client propagates the route (sends the router advertisement).
This way, the k8s nodes know the correct route to the currently active gateway.

---
**NOTE**

Because wireguard is active on all gateways, the (backup) gateways will not import the propagated route advertisement sent by the currently active gateway.
This is because, they think they already have a route to the wireguard subnet.
From this follows, that it is **not possible** to ssh to the secondary gateways **directly**.
You can still connect to them using the public IP address or by using the currently active gateway as jumphost.

---

* agreed on letting the control plane single stack
  * but vipv6 is created
  * and api is callable via it
* not possible to upgrade a single stack cluster to a dualStack cluster