Upgrading Rook and Ceph
=======================

The following sections describe how an existing rook-based ceph cluster
can be updated.

.. _upgrades.supported-rookceph-versions-in-mk8s:

Supported rook/ceph versions in mk8s
------------------------------------

The following table contains all rook versions that can be configured as
well as the corresponding ceph version that will be deployed. The
mapping of a rook to a ceph version is done in the ``k8s-config`` role.

role rook_v1 (manifest based)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. table::
   :align: center

   ============ ============
   rook version ceph version
   ============ ============
   ``v1.2.3``   ``v14.2.5``
   ``v1.3.11``  ``v14.2.21``
   ``v1.4.9``   ``v15.2.13``
   ``v1.5.12``  ``v15.2.13``
   ``v1.6.7``   ``v16.2.5``
   ``v1.7.11``  ``v16.2.6``
   ============ ============

role rook_v2 (Helm based)
~~~~~~~~~~~~~~~~~~~~~~~~~

The rook_v2 role should support any arbitrary helm chart version.
We tested it both on bare metal and on OpenStack up to rook v1.11.

.. warning::

   If you're running on bare metal, prior to the upgrade to rook v1.8
   you must set a
   :ref:`custom ceph version <cluster-configuration.rook-configuration>`
   as the one used by default contains
   the following bug which will fry your cluster:
   `Ceph Bug #55970 <https://tracker.ceph.com/issues/55970>`_
   A version known to work with rook v1.8 is Ceph v16.2.13.

A word of warning / Things to be considered
-------------------------------------------

.. warning::

   Upgrading a Rook cluster is not without risk. There may
   be unexpected issues or obstacles that damage the integrity and
   health of your storage cluster, including data loss. Only proceed
   with this guide if you are comfortable with that.

   The Rook cluster’s storage may be unavailable for short periods
   during the upgrade process for both Rook operator updates and for
   Ceph version updates.

Rook upgrades can only be performed from any official minor release to
the **next** minor release. This means you can only update from
e.g. ``v1.2.* --> v1.3.*``, ``v1.3.* --> v1.4.*``, etc.

Downgrades are theoretically possible, but we do not (want to) cover
automated downgrades.

How to update an existing Cluster
---------------------------------

The rook version to be deployed can be defined in your managed-k8s
cluster configuration via the variable ``version`` in the
``[k8s-service-layer.rook]`` section.

This variable currently defaults to ``v1.2.3`` (which is mapped to ceph
``v14.2.5``).

Upgrade to rook_v2 (Helm-based installation)
--------------------------------------------

1. Make sure rook is at v1.7.11 as that’s the only overlap between both
   roles. (See below for the upgrade procedure)

2. Set ``use_helm=true`` in the ``[k8s-service-layer.rook]`` section

3. Execute ``stage4``, or at least the ``rook_v1/2`` role.

   .. note::

      As the upgrade is disruptive (at least for a short amount of time) >
      disruption needs to be enabled.

   .. code:: shell

      # Trigger stage 4
      MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-stage4.sh
      # Trigger only k8s-rook
      AFLAGS='--diff --tags mk8s-sl/rook' MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-stage4.sh


Steps to perform an upgrade
~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. Make sure you have read this document and checked the
   ``Considerations`` section in the
   `Rook Upgrade Docs <https://rook.io/docs/rook/v1.2/ceph-upgrade.html#considerations>`__.
   (Please select your target version on the Documentation page)

2. Determine which rook version is currently deployed. It should be the
   currently configured rook version in your managed-k8s cluster
   configuration file. To be sure, you can check the actual deployed
   version with the following commands:

   .. code:: shell

      # Determine the actual rook-ceph-operator Pod name
      POD_NAME=$(kubectl -n rook-ceph get pod \
      -o custom-columns=name:.metadata.name --no-headers \
      | grep rook-ceph-operator)
      # Get the configured rook version
      $ kubectl -n rook-ceph get pod ${POD_NAME} \
      -o jsonpath='{.spec.containers[0].image}'

3. (Optional, but informative)

   Determine which ceph version is currently deployed:

   .. code:: console

      $ kubectl -n rook-ceph get CephCluster rook-ceph \
      -o jsonpath='{.spec.cephVersion.image}'

4. Depending on the currently deployed rook version, determine the
   *next* (supported) minor release.The managed-k8s cluster
   configuration template states all supported versions. If in doubt,
   all supported rook releases are also stated in the
   ``k8s-service-layer/rook_v1`` role and at
   :ref:`the top of this document <upgrades.supported-rookceph-versions-in-mk8s>`.

5. Set ``version`` in the
   :ref:`rook configuration section <cluster-configuration.rook-configuration>`
   to the **next** (supported) minor release of rook.

   .. code:: toml

      [...]
      [k8s-service-layer.rook]
      [...]
      # Currently we support the following rook versions:
      # v1.2.3, v1.3.11, v1.4.9, v1.5.12, v1.6.7, v1.7.11
      version = "v1.6.7"
      [...]

6. Execute ``stage4``, or at least the ``rook_v1/2`` role.

   .. note::

      As the upgrade is disruptive (at least for a short amount of time) >
      disruption needs to be enabled.

   .. code:: shell

      # Trigger stage 4
      MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-stage4.sh
      # Trigger only k8s-rook
      AFLAGS='--diff --tags mk8s-sl/rook' MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-stage4.sh

7. Get yourself your favorite (non-alcoholic) drink and watch with
   fascinating enthusiasm how your rook-based ceph cluster gets
   upgraded. (Can take several minutes (up to hours)).

8. After the upgrade has been proceeded, check that your managed-k8s
   cluster still is in a sane state via the smoke tests.

   .. code:: console

      $ bash managed-k8s/actions/test.sh

9. Continue with steps ``{1,3..10}`` until you have reached your final
   target rook version.

10. Celebrate that everything worked out ``ᕕ( ᐛ )ᕗ``

Updating rook manually
~~~~~~~~~~~~~~~~~~~~~~

Currently, there is only one major release of rook.

Updating rook to a new patch version is fairly easy and fully automated
by rook itself. You can simply patch the image version of the
``rook-ceph-operator``.

.. code:: shell

   # Example for the update of rook
   # to a new (fictional) patch version of v1.7.*
   $ kubectl -n rook-ceph set image deploy/rook-ceph-operator rook-ceph-operator=rook/ceph:v1.7.42

Updating rook to a new minor release usually requires additional steps.
These steps are described in the corresponding
`upgrade section of the rook Docs <https://rook.io/docs/rook/v1.2/ceph-upgrade.html#upgrading-from-v11-to-v12>`__.

Updating ceph manually
~~~~~~~~~~~~~~~~~~~~~~

Updating ceph is fully automated by rook. As long as the currently
deployed ``rook-ceph-operator`` supports the configured ceph version,
the operator will perform the update without the need of further
intervention Just ensure that the ceph version really is supported by
the currently deployed rook version.

.. code:: shell

   # Example for the update of ceph to
   # a new (fictional) release v17.2.42
   $ kubectl -n rook-ceph patch CephCluster rook-ceph --type=merge -p "{\"spec\": {\"cephVersion\": {\"image\": \"ceph/ceph:v17.2.42\"}}}"

Adding/Implementing support for a new rook/ceph release to managed-k8s
----------------------------------------------------------------------

Adding support for a new rook or ceph release may be accomplished by
the following steps.

Adding support for a new rook release
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Check for new releases in the
`rook Github repository <https://github.com/rook/rook/releases>`__.
Read the corresponding upgrade page at the
`rook Docs <https://rook.github.io/docs/rook/latest/Getting-Started/intro/>`__.
**Especially check the** ``Considerations`` **section there**.

-  Most upgrade steps will be taken care of by Helm
-  In case any changes need to be made to the values of one of the charts,
   place them inside an if block, e.g.:

   .. code:: jinja

      {% if rook_version[1:] is version('1.9', '>=') %}
         createPrometheusRules: true
      {% endif %}

-  If necessary, implement any additional steps described in the `rook Docs <https://rook.io/docs/rook/latest/>`__

   -  Please also include the cluster health verification task prior and
      subsequent to the actual upgrade steps. As the ``ceph status``
      update can slightly differ from release to release, you may need
      to adjust the cluster health verification tasks. You have to
      ensure backwards compatibility when adjusting these tasks.

-  Make sure your implemented upgrade tasks are included at the right
   place and under the correct circumstances in ``version_checks.yaml``
-  **Test your changes**

   -  Configure the new rook version in your managed-k8s cluster
      configuration
   -  Make sure the correct upgrade tasks are included
   -  The ``rook-ceph-operator`` logs are very helpful to observe the
      upgrade
   -  Execute the smoke tests

Adding support for a new ceph release
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you notice that a new ceph release is available, I do not recommend
modifying/updating the mapped ceph version of an already existing rook
release in ``k8s-config``. This would trigger existing clusters to
perform a ceph upgrade once the change is merged.

Rook is getting patch releases on a relatively frequent basis. If a new
patch version of rook is released, you can add it to the supported
releases map in ``k8s-config`` along with the new ceph version you want
to have support for. Patch version upgrades of rook do not require
additional steps. In other words: Once a ceph release is bound to a rook
release, do not change that. This way we ensure that existing clusters
will not be accidentally upgraded (to a new ceph release).

References
----------

-  `Rook-Ceph Upgrade Docs v1.2 <https://rook.io/docs/rook/v1.2/ceph-upgrade>`__
-  `Rook-Ceph Upgrade Docs v1.3 <https://rook.io/docs/rook/v1.3/ceph-upgrade>`__
-  `Rook-Ceph Upgrade Docs v1.4 <https://rook.io/docs/rook/v1.4/ceph-upgrade>`__
-  `Rook-Ceph Upgrade Docs v1.5 <https://rook.io/docs/rook/v1.5/ceph-upgrade>`__
-  `Rook-Ceph Upgrade Docs v1.6 <https://rook.io/docs/rook/v1.6/ceph-upgrade>`__
-  `Rook-Ceph Upgrade Docs v1.7 <https://rook.io/docs/rook/v1.7/ceph-upgrade>`__
-  `Rook Repository (Github) <https://github.com/rook/rook>`__
-  `Ceph Docker Images <https://hub.docker.com/r/ceph/ceph>`__
-  `Ceph Health Checks Docs <https://docs.ceph.com/en/latest/rados/operations/health-checks/>`__
