.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway:

yk8s.k8s-service-layer.envoy-gateway
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.crds.helm.chart_ref:

``yk8s.k8s-service-layer.envoy-gateway.crds.helm.chart_ref``
############################################################

The chart reference (relative to the repository) of the envoy-gateway-crds Helm chart.


**Type:**::

  RFC3986 relative URL path or RFC3986 URL


**Default:**::

  "oci://docker.io/envoyproxy/gateway-crds-helm"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.crds.helm.chart_repo_url:

``yk8s.k8s-service-layer.envoy-gateway.crds.helm.chart_repo_url``
#################################################################

The URL to the Helm repository for the envoy-gateway-crds Helm chart.


**Type:**::

  null or RFC3986 URL


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.crds.helm.chart_version:

``yk8s.k8s-service-layer.envoy-gateway.crds.helm.chart_version``
################################################################

Version of the envoy-gateway-crds Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "v1.8.2"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.crds.helm.release_name:

``yk8s.k8s-service-layer.envoy-gateway.crds.helm.release_name``
###############################################################

The release name inside the cluster for envoy-gateway-crds.


**Type:**::

  non-empty string


**Default:**::

  "envoy-gateway-crds"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.crds.helm.release_namespace:

``yk8s.k8s-service-layer.envoy-gateway.crds.helm.release_namespace``
####################################################################

The namespace in which to install envoy-gateway-crds.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "envoy-gateway-system"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.crds.helm.values:

``yk8s.k8s-service-layer.envoy-gateway.crds.helm.values``
#########################################################

Helm values for the envoy-gateway-crds helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://github.com/envoyproxy/gateway/blob/main/charts/gateway-crds-helm/README.md


**Type:**::

  open submodule of (attribute set containing JSON compatible values)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.crds.helm.values.crds.gatewayAPI.channel:

``yk8s.k8s-service-layer.envoy-gateway.crds.helm.values.crds.gatewayAPI.channel``
#################################################################################

  The `Release Channel <https://gateway-api.sigs.k8s.io/docs/concepts/versioning>`_ to use.

.. note::

  Switching the channel may involve manual steps. Check the documentation linked above.



**Type:**::

  one of "standard", "experimental"


**Default:**::

  "standard"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.enabled:

``yk8s.k8s-service-layer.envoy-gateway.enabled``
################################################

Whether to enable Envoy Gateway.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.gateway_class_name:

``yk8s.k8s-service-layer.envoy-gateway.gateway_class_name``
###########################################################

The name of the default GatewayClass


**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "envoy-gateway"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.helm.chart_ref:

``yk8s.k8s-service-layer.envoy-gateway.helm.chart_ref``
#######################################################

The chart reference (relative to the repository) of the envoy-gateway Helm chart.


**Type:**::

  RFC3986 relative URL path or RFC3986 URL


**Default:**::

  "oci://docker.io/envoyproxy/gateway-helm"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.helm.chart_repo_url:

``yk8s.k8s-service-layer.envoy-gateway.helm.chart_repo_url``
############################################################

The URL to the Helm repository for the envoy-gateway Helm chart.


**Type:**::

  null or RFC3986 URL


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.helm.chart_version:

``yk8s.k8s-service-layer.envoy-gateway.helm.chart_version``
###########################################################

Version of the envoy-gateway Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "v1.8.2"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.helm.release_name:

``yk8s.k8s-service-layer.envoy-gateway.helm.release_name``
##########################################################

The release name inside the cluster for envoy-gateway.


**Type:**::

  non-empty string


**Default:**::

  "envoy-gateway"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.helm.release_namespace:

``yk8s.k8s-service-layer.envoy-gateway.helm.release_namespace``
###############################################################

The namespace in which to install envoy-gateway.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "envoy-gateway-system"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.helm.values:

``yk8s.k8s-service-layer.envoy-gateway.helm.values``
####################################################

Helm values for the envoy-gateway helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://github.com/envoyproxy/gateway/blob/main/charts/gateway-helm/README.md


**Type:**::

  open submodule of (attribute set containing JSON compatible values)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix


.. _configuration-options.yk8s.k8s-service-layer.envoy-gateway.install:

``yk8s.k8s-service-layer.envoy-gateway.install``
################################################

If enabled, choose whether to install or uninstall envoy-gateway. IF SET TO
FALSE, envoy-gateway WILL BE DELETED WITHOUT CHECKING FOR DISRUPTION.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/envoy-gateway.nix

