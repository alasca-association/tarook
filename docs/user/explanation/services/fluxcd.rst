FluxCD
======

The ``fluxcd2_v2`` role deploys a useful set of controllers
(`fluxcd <https://fluxcd.io/>`__) into the Kubernetes cluster
via the `fluxcd2 community helm chart <https://github.com/fluxcd-community/helm-charts/>`__
, to manage further K8s workload in a GitOps manner.

The installation can be activated by setting

.. code:: nix

   k8s-service-layer.fluxcd.enabled = true;

For further configuration options please refer to
:ref:`the Flux configuration section <configuration-options.yk8s.k8s-service-layer.fluxcd>`.

To learn more about fluxcd, please refer to the
`official documentation <https://fluxcd.io/flux/concepts/>`__
of the tool.
