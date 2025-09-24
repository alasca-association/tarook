Teardown
========

To tear down your cluster, remove the lock file ``./state/terraform/prevent_disruption.lock``.

Then run:

.. code:: console

    $ MANAGED_K8S_NUKE_FROM_ORBIT=true MANAGED_K8S_DISRUPT_THE_HARBOUR=true MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/destroy.sh
