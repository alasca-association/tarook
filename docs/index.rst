Welcome to Yaook k8s' documentation!
====================================

.. toctree::
   :maxdepth: 2
   :caption: Getting Started
   :hidden:

   getting_started/introduction
   Quick Start: How to Deploy a yk8s Cluster <getting_started/quick-start>
   getting_started/faq
   releasenotes

.. toctree::
   :maxdepth: 2
   :caption: Concept
   :hidden:

   concepts/cluster-repository
   concepts/abstraction-layers

.. toctree::
   :maxdepth: 2
   :caption: LCM Usage Guide
   :hidden:

   Cluster Repository Initialization <usage/initialization>
   Environment Variables <usage/environmental-variables>
   Cluster Configuration <usage/cluster-configuration>
   Terraform Documentation <usage/terraform-docs>

.. toctree::
   :maxdepth: 2
   :caption: Operating a yk8s-Cluster
   :hidden:

   operation/actions-references
   operation/spawning-cluster
   Node Scheduling (Taints and Labels) <operation/node-scheduling>
   operation/upgrading-kubernetes
   operation/updating-host-nodes
   operation/gpu-and-vgpu
   operation/resetting-kubernetes
   operation/backups
   operation/snapshots
   Calico (CNI) <operation/calico>
   Vault secret store <operation/vault>

.. toctree::
   :maxdepth: 3
   :caption: Managed Services
   :hidden:

   Rook-based Ceph Cluster <managed-services/rook/overview>
   Monitoring <managed-services/prometheus/overview>
   managed-services/load-balancing/overview
   managed-services/nginx-ingress-controller
   managed-services/cert-manager
   managed-services/vault
   managed-services/fluxcd

.. toctree::
   :maxdepth: 2
   :caption: VPN
   :hidden:

   vpn/wireguard
   vpn/ipsec

.. toctree::
   :maxdepth: 2
   :caption: Development
   :hidden:

   development/coding-guide
   development/vault

.. toctree::
   :maxdepth: 2
   :caption: MISC
   :hidden:

   DualStack-Support <misc/dualstack>
   misc/rook-ceph-notes
   misc/increase-cluster-cidr
