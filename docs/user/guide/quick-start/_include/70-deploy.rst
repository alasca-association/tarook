Deploy your cluster by executing the :ref:`apply-all.sh <actions-references.apply-allsh>` script.

.. code:: console

   $ tarook apply all

Get yourself a hot beverage and joyfully watch as your Tarook cluster gets created.

This will do a full deploy and consists of multiple stages.
You can also execute these steps manually one after another
instead of directly calling ``apply-all.sh``.
In case you want to better understand what's going on -
simply check the :doc:`script </user/reference/actions-references>`
for what to execute in which order.

.. note::

    If you change the Cloud configuration in a destructive manner
    (decrease node counts, change flavors etc.)
    after having the previous config already deployed,
    these changes will not be applied by default
    to avoid havoc.
    For that case,
    you need to use an additional environment variable.
    You should not export that variable
    to avoid breaking things by accident.

    Remove the lock file ``./state/terraform/prevent_disruption.lock``

    Then run

    .. code:: console

        $ MANAGED_K8S_DISRUPT_THE_HARBOUR=true bash managed-k8s/actions/apply-terraform.sh

Afterwards you may verify that it's functional by running our smoke tests.

.. code:: console

   $ tarook test


Start using your cluster.
Try ``kubectl get nodes`` for example.

Would you like to have a visualisation of your cluster?
Just install `k9s <https://k9scli.io/>`__ and then run it:

.. code:: console

    $ k9s

The next time you would like to play with your Tarook cluster
(e.g., after a workstation reboot),
please don't forget to open the directory with your cluster to load the environment,
and to establish the WireGuard connection:

.. code:: console

    $ bash managed-k8s/actions/wg-up.sh
