Rotate OpenStack Credentials
============================

The following document describes the necessary actions
that must be taken LCM-wise after an OpenStack credential rotation.

1. Change the OpenStack credentials (how to do that is out of scope).
2. Trigger rotation of managed components

   .. tabs::

      .. tab:: ch-k8s-lbaas disabled

         Immediately afterwards renew the OpenStack connection of the Kubernetes cluster.
         This will update the ``kube-system/cloud-config`` secret
         and restart the cloud-controller-manager, csi-cinder-controllerplugin and
         csi-cinder-nodeplugin in the ``kube-system`` namespace.

         .. code:: console

            $ bash managed-k8s/actions/apply-k8s-supplements.sh connect-k8s-to-openstack.yaml

      .. tab:: ch-k8s-lbaas enabled

         Immediately afterwards renew the OpenStack connection of the Kubernetes cluster.
         This will update the ``kube-system/cloud-config`` secret
         and restart the cloud-controller-manager, csi-cinder-controllerplugin and
         csi-cinder-nodeplugin in the ``kube-system`` namespace.
         It will also update the ``kube-system/ch-k8s-lbaas-controller-config`` secret and restart
         the ch-k8s-lbaas-controller in the ``kube-system`` namespace.

         .. code:: console

            $ bash managed-k8s/actions/apply-k8s-supplements.sh connect-k8s-to-openstack.yaml
            $ bash managed-k8s/actions/apply-k8s-supplements.sh install-ch-k8s-lbaas.yaml

3. Verify that everything is able to come up after it has been restarted.
4. Check which Pods besides the above mentioned have mounted the ``kube-system/cloud-config`` secret:

   .. code:: shell

      kubectl get pods --all-namespaces -o json | jq --raw-output '.items[]
          | select(.spec | has("volumes"))
          | select(.spec.volumes[].secret.secretName=="cloud-config")
          | "\(.metadata.namespace)/\(.metadata.name)"'

5. Check which Pods are referencing the ``kube-system/cloud-config`` secret in their env:

   .. code:: shell

      kubectl get pods--all-namespaces -o json | jq --raw-output '.items[]
          | select(.spec.containers[].env[]?.valueFrom.secretKeyRef.name=="cloud-config")
          | "\(.metadata.namespace)/\(.metadata.name)\n"'

6. Figure out how these Pods are controlled and (rollout) restart them.

7. Update Thanos bucket configuration

   .. tabs::

      .. tab:: Thanos enabled

         Thanos is enabled if :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.use_thanos` is set to ``true``.
         If the custom bucket management setting :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.manage_thanos_bucket`
         is unset or set to ``true``, apply the required changes by running the following update script:

         .. code:: shell

            $ bash managed-k8s/actions/apply-k8s-supplements.sh install-monitoring.yaml

         This ensures that the Kubernetes secret ``thanos-bucket-config`` for Thanos is updated.

      .. tab:: Thanos disabled

         Thanos is disabled if :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.use_thanos` is unset or set to ``false``.

         In this case, no further action is necessary.
