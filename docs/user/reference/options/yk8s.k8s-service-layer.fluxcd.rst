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


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.helm.chart_ref:

``yk8s.k8s-service-layer.fluxcd.helm.chart_ref``
################################################

The chart reference (relative to the repository) of the fluxcd Helm chart.


**Type:**::

  RFC3986 relative URL path


**Default:**::

  "flux2"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.helm.chart_repo_url:

``yk8s.k8s-service-layer.fluxcd.helm.chart_repo_url``
#####################################################

The URL to the Helm repository for the fluxcd Helm chart.


**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://fluxcd-community.github.io/helm-charts"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.helm.chart_version:

``yk8s.k8s-service-layer.fluxcd.helm.chart_version``
####################################################

Version of the fluxcd Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "2.18.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.helm.release_name:

``yk8s.k8s-service-layer.fluxcd.helm.release_name``
###################################################

The release name inside the cluster for fluxcd.


**Type:**::

  non-empty string


**Default:**::

  "flux2"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.helm.release_namespace:

``yk8s.k8s-service-layer.fluxcd.helm.release_namespace``
########################################################

The namespace in which to install fluxcd.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "k8s-svc-flux-system"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/fluxcd.nix


.. _configuration-options.yk8s.k8s-service-layer.fluxcd.helm.values:

``yk8s.k8s-service-layer.fluxcd.helm.values``
#############################################

Helm values for the fluxcd helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://github.com/fluxcd-community/helm-charts/blob/main/charts/flux2/values.yaml


**Type:**::

  attribute set containing JSON compatible values


**Default:**::

  { }


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

