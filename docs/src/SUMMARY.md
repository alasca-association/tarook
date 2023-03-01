# yk8s Summary

- [Introduction](./introduction.md)
- [Quick Start: How to Deploy a yk8s Cluster](./quick-start.md)
- [FAQ and Troubleshooting](./faq.md)

---

# Design & Concepts

- [Cluster Repository](./design/cluster-repository.md)
- [Abstraction Layers](./design/abstraction-layers.md)

---

# LCM Usage Guide

- [Cluster Repository Initialization](./usage/initialization.md)
- [Environment Variables](./usage/environmental-variables.md)
- [Cluster Configuration](./usage/cluster-configuration.md)

---

# Operating a yk8s-Cluster

- [Actions References](./operation/actions-references.md)
- [Spawning a Cluster]() <!-- ./operation/spawning-cluster.md -->
- [Node Scheduling (Taints and Labels)](./operation/node-scheduling.md)
- [Upgrading Kubernetes](./operation/upgrading-kubernetes.md)
- [Updating Host Nodes]() <!-- ./operation/updating-host-nodes.md -->
- [GPU and vGPU Support](./operation/gpu-and-vgpu.md)
- [vGPU Support](./operation/vgpu-support.md)
- [Resetting Kubernetes]() <!-- ./operation/resetting-kubernetes.md -->
- [Backups](./operation/backups.md)
- [Migrate CRI from docker to containerd](./operation/migrate-docker-containerd.md)
- [Vault secret store](./operation/vault.md)

---

# Managed Services

- [Rook-based Ceph Cluster](./managed-services/rook/overview.md)
  - [General Information](./managed-services/rook/general-information.md)
  - [Reducing the number of OSDs](./managed-services/rook/removing-osds.md)
  - [Resizing an OSD](./managed-services/rook/resizing-osds.md)
  - [Upgrading Rook and Ceph](./managed-services/rook/upgrades.md)
  - [Custom Storage Configuration](./managed-services/rook/custom-storage.md)
- [Monitoring]() <!-- ./managed-services/prometheus/overview.md -->
  - [Prometheus-based Monitoring Stack](./managed-services/prometheus/prometheus-stack.md)
  - [Global Monitoring]() <!-- ./managed-services/prometheus/global-monitoring.md -->
- [Load-Balancing]() <!-- ./managed-services/load-balancing/overview.md -->
  - [ch-k8s-lbaas](./managed-services/load-balancing/ch-k8s-lbaas.md)
- [NGINX Ingress Controller]() <!-- ./managed-services/nginx-ingress-controller.md -->
- [Cert-Manager]() <!-- ./managed-services/cert-manager.md -->
- [HashiCorp Vault](./managed-services/vault.md)
- [FluxCD](./managed-services/fluxcd.md)

---

# VPN

- [Wireguard](./vpn/wireguard.md)
- [IPsec](./vpn/ipsec.md)

---

# Development & Contribution

- [Coding Guide](./development/coding-guide.md)
- [Developing with Vault](./development/vault.md)

---

# MISC

* [DualStack-Support](./misc/dualstack.md)
* [Initial Test Notes for Rook Ceph](./misc/rook-ceph-notes.md)
* [Increase k8s cluster-cidr](./misc/increase-cluster-cidr.md)
