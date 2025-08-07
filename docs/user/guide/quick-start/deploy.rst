Cluster Deployment
==================

Deploy your cluster by executing the :ref:`apply-all.sh <actions-references.apply-allsh>` script.

.. code:: console

   $ ./managed-k8s/actions/apply-all.sh

Get yourself a hot beverage and joyfully watch as your YAOOK/K8s cluster gets created.

Afterwards you may verify that it's functional by running our smoke tests.

.. code:: console

   $ ./managed-k8s/actions/test.sh


Start using your cluster.
Try ``kubectl get nodes`` for example.
