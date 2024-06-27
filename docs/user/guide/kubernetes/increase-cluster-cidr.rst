Increase k8s cluster CIDR
=========================

.. note::

   Calico IPPools have to be inside the cluster-cidr

.. hint::

   The extended cluster-cidr could be ``10.224.0.0/11`` which contains
   our old cluster-cidr (``10.244.0.0/16``)

Steps to change the cluster-cidr:
---------------------------------

1. Change podSubnet in kubeadm configmap: kube-system/kubeadm-config

2. Change clusterCIDR in kube-proxy configmap: kube-system/kube-proxy

3. Change cluster-cidr on every master node:
   ``/etc/kubernetes/manifests/kube-controller-manager.yaml``

   kubelet will automatically recreate the kube-controller container

4. add additional calico ippools:

   .. code:: yaml

      apiVersion: projectcalico.org/v3
      kind: IPPool
      metadata:
        name: additional-ippool-10.224
      spec:
        blockSize: 26
        cidr: 10.224.0.0/16
        ipipMode: Always
        natOutgoing: true
        nodeSelector: all()
        vxlanMode: Never

   => `IPPools have to be applied with calicoctl instead of kubectl <https://github.com/projectcalico/calico/issues/2923>`__.

5. Optional: change pod_subnet in
   ``/var/lib/metal-controller/{CLUSTER}/config`` in the
   metal-controller running in the deploy cluster.

   .. hint::

      This is just for documentation purposes because kubeadm
      picks for new masternodes the range specified in the kubeadm
      configmap
