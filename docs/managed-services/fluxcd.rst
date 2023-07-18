FluxCD
======

The ``fluxcd2_v1`` role deploys a useful set of controllers
(`fluxcd <https://fluxcd.io/>`__) into the kubernetes cluster, to manage
further k8s workload in a GitOps manner.

The installation can be activated by setting the ``enabled`` field in
the ``k8s-service-layer.fluxcd`` to ``true``.

.. code:: toml

   [k8s-service-layer.fluxcd]
   enabled = true

To learn more about fluxcd, please refer to the
`official documentation <https://fluxcd.io/flux/concepts/>`__
of the tool.
