Configure cluster
=================

.. include:: ../_include/50-cluster.tpl.rst

- :ref:`configuration-options.yk8s.infra.cluster_name`
- :ref:`configuration-options.yk8s.infra.subnet_cidr`
- :ref:`configuration-options.yk8s.proxmox.enabled`
- :ref:`configuration-options.yk8s.proxmox.ipv4_gateway_address`
  and/or :ref:`configuration-options.yk8s.proxmox.ipv6_gateway_address`
- :ref:`configuration-options.yk8s.proxmox.pool_id`
- :ref:`configuration-options.yk8s.proxmox.clone.vm_id`
- :ref:`configuration-options.yk8s.proxmox.clone.node_name`
- :ref:`configuration-options.yk8s.proxmox.datastore_id`
- :ref:`configuration-options.yk8s.proxmox.nodes`

.. todo::
   TODO: @proxmox::MTU
   remove when MTU for Proxmox has been implemented

.. note::
   Calico's MTU is set to a default of ``1500`` for non-OpenStack deployments.

   In eBPF mode, VXLAN is used to forward Kubernetes NodePort traffic.
   Depending on your network configuration, you need to manually adjust
   :ref:`configuration-options.yk8s.kubernetes.network.calico.helm.values.installation.calicoNetwork.mtu`.
