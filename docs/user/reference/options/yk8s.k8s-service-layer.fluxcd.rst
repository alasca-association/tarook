.. _configuration-options.yk8s.k8s-service-layer.fluxcd:

yk8s.k8s-service-layer.fluxcd
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


More details about our FluxCD2 implementation can be found
:doc:`here </user/explanation/services/fluxcd>`.

The following configuration options are available:

.. _configuration-options.yk8s.k8s-service-layer.fluxcd.enabled:

``yk8s.k8s-service-layer.fluxcd.enabled``
#########################################

Whether to enable Flux management.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.helm_repo_url:

``yk8s.k8s-service-layer.fluxcd.helm_repo_url``
###############################################



**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://fluxcd-community.github.io/helm-charts"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.install:

``yk8s.k8s-service-layer.fluxcd.install``
#########################################

If enabled, choose whether to install or uninstall fluxcd2. IF SET TO
FALSE, FLUXCD2 WILL BE DELETED WITHOUT CHECKING FOR DISRUPTION.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.namespace:

``yk8s.k8s-service-layer.fluxcd.namespace``
###########################################

Namespace to deploy the flux-system in (will be created if it does not exist, but
never deleted).


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "k8s-svc-flux-system"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.scheduling_key:

``yk8s.k8s-service-layer.fluxcd.scheduling_key``
################################################

Scheduling key for the flux instance and its resources. Has no
default.


**Type:**::

  null or Kubernetes label


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.version:

``yk8s.k8s-service-layer.fluxcd.version``
#########################################

Helm chart version of FluxCD to be deployed.


**Type:**::

  OCI image tag


**Default:**::

  "2.16.4"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix

