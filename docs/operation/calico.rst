Calico
======

General Information
-------------------

Calico will be setup by using the operator-based
approach. More detailed: the
`Tigera Calico Operator <https://docs.tigera.io/calico/3.25/getting-started/kubernetes/helm#how-to>`__
is deployed. The Tigera operator is deployed via ``helm``.

It is possible to customize the Calico setup to some extend. Please
check out the
:ref:`calico configuration section <cluster-configuration.calico-configuration>`
for options.

In addition to the Tigera operator which rolls out and sets up the basic
Calico installation, the
`Calico API servers <https://docs.tigera.io/calico/3.25/operations/install-apiserver>`__
are configured and deployed. This allows to manage Calico-specific
resources via ``kubectl``. However, note that this currently does not
replace the complete functionality of
`calicoctl <https://github.com/projectcalico/calico/tree/master/calicoctl#calicoctl>`__.
Therefore, we’re still deploying ``calicoctl`` on all control-plane
nodes.

.. _calico.versioning:

Versioning
----------

For each release, Calico published the Kubernetes versions the release
has been tested on. E.g., for Calico v3.25 this section can be found
`here <https://docs.tigera.io/calico/3.25/getting-started/kubernetes/requirements#supported-versions>`__.

If not manually adjusted, the Calico version to be deployed is the one
mapped to the Kubernetes version in
`k8s-config <https://gitlab.com/yaook/k8s/-/blob/devel/k8s-base/roles/k8s-config/defaults/main.yaml>`__.

However, it is possible to configure a custom version via the
``[kubernetes.network.calico.custom_version]`` (see
:ref:`here <cluster-configuration.network-configuration>`)
variable in the ``[kubernetes.network]`` section of your
cluster-specific ``config/config.toml``.

Manually Upgrade Calico
~~~~~~~~~~~~~~~~~~~~~~~

Please note what is written in the :ref:`versioning section <calico.versioning>`
above.

After updating the variable, you then can update calico by executing the
following. Note that this is a (slightly) disruptive action:

.. code:: console

   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true AFLAGS="--diff -t calico" bash managed-k8s/actions/apply-stage3.sh

Optionally but recommended, you can verify the calico functionality
afterwards by triggering the test role:

.. code:: console

   $ AFLAGS="--diff -t check-calico" bash managed-k8s/actions/test.sh
