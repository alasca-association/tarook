.. note::
   If you plan on deploying OpenStack using `YAOOK/Operator <https://gitlab.com/yaook/operator>`_
   on top of your Tarook cluster, please refer to the
   `cluster requirements of yaook/operator <https://docs.yaook.cloud/user/explanations/requirements/k8s-cluster.html>`__
   to see which features are recommended and required to be present in
   your Kubernetes cluster.

There are
:doc:`many configuration options available </user/reference/options/index>`,
but the minimum set of options that need to be set in the configuration file ``./config/default.nix`` within the cluster repository
are the following ones:
