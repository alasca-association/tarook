# Automatic Configuration of Calico as CNI Plugin

These tasks basically follow the [Calico the hard way](https://docs.projectcalico.org/getting-started/kubernetes/hardway/) steps to deploy Calico as CNI-Plugin on Kubernetes. The following points wrap up the goal of the setup:

* Kubernetes as Datastore
* Calico CNI Plugin with BGP-based networking
* Calico IPAM (IP Address Management)
* No overlays
* IPv4 addresses
  * refer #227 for DualStack support
* Highly available Typha with mutually authenticated TLS

## Preliminaries

(The preliminaries can be fulfilled by executing the `setup_calico.yaml` task of the `k8s-master` and `k8s-worker` roles)

* Calico resources are stored as Kubernetes custom resources
  * `wget https://docs.projectcalico.org/manifests/crds.yaml`
* `calicoctl` binary is installed on the k8s-master nodes and configured to access Kubernetes
  * necessary to interact directly with the Calico datastore
* The CNI plugin is installed and configured on every kubernetes node
  * refer [Install CNI plugin](https://docs.projectcalico.org/getting-started/kubernetes/hardway/install-cni-plugin)
  * (including the certificate setup)
* RBAC support and configuration

## Calico Datastore

Calico has two datastore drivers to choose from:

* **etcd** - for direct connection to an etcd cluster
* **Kubernetes** - for connection to a Kubernetes API server

In the mk8s context, **Kubernetes** is used as Datastore for now.

## Setup Steps Overview

* [Configure IP pools](https://docs.projectcalico.org/getting-started/kubernetes/hardway/configure-ip-pools)
  * [`setup_ippools.yaml`](tasks/setup_ippools.yaml)
* [Setup Typha](https://docs.projectcalico.org/getting-started/kubernetes/hardway/install-typha)
  * [`setup_typha.yaml`](tasks/setup_typha.yaml)
* [Setup calico/node](https://docs.projectcalico.org/getting-started/kubernetes/hardway/install-node)
  * [`setup_calico_node.yaml`](tasks/setup_calico_node.yaml)
* [Setup BGP-based routing information distribution](https://docs.projectcalico.org/reference/resources/bgpconfig)
  * [`setup_bgp.yaml`](tasks/setup_bgp.yaml)
  * In addition to configuring the k8s nodes, the gateway nodes must establish a connection to the k8s-masters (refer the ['bird' role](../bird/templates/bird.conf))

## Upgrading Calico Resources

To upgrade the Calico resources, basically follow this guide: [Upgrading an installation that uses the Kubernetes API datastore]([)](https://docs.projectcalico.org/maintenance/kubernetes-upgrade#upgrading-an-installation-that-uses-the-kubernetes-api-datastore).

* adjust the calico custom resources in [`k8s-master`](../k8s-master/)
* adjust the calico version in [`k8s-config`](../k8s-config/defaults/main.yaml)
* remove any existing `calicoctl` instances and rerun `stage 3` with the new version number

## Things to Consider

* Which IP pool shall be used?
  * refer [IP pool template](templates/ippools.yaml.j2)
* Which Cluster ID shall be used?
  * refer [`k8s-config`](../k8s-config/defaults/main.yaml)
* Which AS number shall be used for the Pod-to-Pod communication?
  * refer [`k8s-config`](../k8s-config/defaults/main.yaml)
* Which AS number is used by for the peering of gateway nodes and masters?
  * refer [`k8s-config`](../k8s-config/defaults/main.yaml)

