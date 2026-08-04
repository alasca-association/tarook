How to Upgrade to a new TAROOK release
=========================================

In this tutorial, we will guide you step-by-step through the process of upgrading
to a new Tarook release.

Carefully read the whole document before taking any actions.
Also verify that you are looking at the documentation of the target release version.
All currently available releases can be found on the
`Gitlab releases page <https://gitlab.com/alasca.cloud/tarook/tarook/-/releases>`_.


.. important::

    Ensure your cluster is running a Kubernetes version
    which is still supported by the target release.
    If your cluster is running on an older Kubernetes version,
    you must do a :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>` first.

Starting out we assume you have got
an **up to date** and usable cluster repo in front of you
plus solid understanding of `git submodules <https://git-scm.com/book/en/v2/Git-Tools-Submodules>`_.

All steps are to performed from the cluster repo's root.

Choosing the target TAROOK release
-------------------------------------

It is recommended to consult the :doc:`Releasenotes </releasenotes>`
of each intermediate version in any case.
Details about the used scheme can be found at
:doc:`Release and Versioning Policy </developer/explanation/release-and-versioning-policy>`.

You can use the following to figure out the currently used release:

.. code:: console

    $ git submodule status managed-k8s

    $ cat managed-k8s/version

Patch Versions
^^^^^^^^^^^^^^

Skipping patch versions is generally safe because they typically contain backward-compatible fixes and improvements.
This means, it is feasible to jump to any available next patch release.

Minor Versions
^^^^^^^^^^^^^^

Skipping minor versions is usually supported, but it’s highly recommended to carefully review the releasenotes
including releasenotes of intermediate releases.
This means, it is feasible to jump to any available next minor release.


Major Versions
^^^^^^^^^^^^^^

Skipping major versions is not supported as these
introduce breaking changes which may require manual intervention or adjustments.
This means, it is only feasible to move to the next available major release.
You can directly jump to any available minor version of the next major release though.

.. important::

   You **must** read the :doc:`Releasenotes </releasenotes>`
   of each intermediate version
   if you want to upgrade to a new major release.

Performing the TAROOK Upgrade
--------------------------------

1. If enabled, establish the WireGuard connection:

   .. code:: console

      $ tarook wireguard up

2. Ensure you have a :ref:`valid kubeconfig<actions-references.k8s-loginsh>`
   and access to the Kubernetes API:

   .. code:: console

      $ tarook k8s-login

      $ kubectl get nodes

3. Move to the target release branch

   .. tabs::

      .. tab:: Major Release Upgrade

         Update the Tarook submodule to the next major version:

         .. code:: console

            $ # Assuming release/v7.0 is currently in use
            $ # and you want to update to release/v8.0
            $ git submodule set-branch --branch release/v8.0 managed-k8s
            $ git submodule update --remote managed-k8s

      .. tab:: Minor Release Upgrade

         Update the Tarook submodule to a specific minor version:

         .. code:: console

            $ # Assuming release/v8.0 is currently in use
            $ # and you want to update to release/v8.1
            $ git submodule set-branch --branch release/v8.1 managed-k8s
            $ git submodule update --remote managed-k8s

      .. tab:: Patch Release Upgrade

         Update the Tarook submodule to the latest available patch version:

         .. code:: console

            $ git submodule update --remote managed-k8s

4. Additional intermediate steps

   .. tabs::

      .. tab:: Major Release Upgrade

         **Follow every instruction** mentioned in the :doc:`Releasenotes </releasenotes>`
         of each intermediate version.
         In most cases, necessary steps to move to the next major release are automated:

         .. code:: console

            $ tarook migrate-to-release

      .. tab:: Patch and Minor Release Upgrades

         No additional intermediate steps needed.

5. Trigger a complete rollout:

   .. code:: console

      $ tarook apply all

6. Verify the upgrade.
   Confirm that the Kubernetes cluster is functioning as expected after the upgrade
   by triggering the tests and checking the nodes and Pods.

   .. code:: console

      $ tarook test

      $ kubectl get nodes -o wide
      $ kubectl get pods -A | grep -Ev "Running|Completed"
