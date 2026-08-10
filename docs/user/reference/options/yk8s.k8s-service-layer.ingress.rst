.. _configuration-options.yk8s.k8s-service-layer.ingress:

yk8s.k8s-service-layer.ingress
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


The used NGINX ingress controller setup will be explained in more detail
soon :)

.. note::

  To enable an ingress controller,
  :ref:`configuration-options.yk8s.k8s-service-layer.ingress.enabled` needs to be set to ``true``.

.. _configuration-options.yk8s.k8s-service-layer.ingress.enabled:

``yk8s.k8s-service-layer.ingress.enabled``
##########################################

Whether to enable nginx-ingress management..

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.chart_ref:

``yk8s.k8s-service-layer.ingress.helm.chart_ref``
#################################################

The chart reference (relative to the repository) of the ingress-nginx Helm chart.


**Type:**::

  RFC3986 relative URL path or RFC3986 URL


**Default:**::

  "ingress-nginx"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.chart_repo_url:

``yk8s.k8s-service-layer.ingress.helm.chart_repo_url``
######################################################

The URL to the Helm repository for the ingress-nginx Helm chart.


**Type:**::

  null or RFC3986 URL


**Default:**::

  "https://kubernetes.github.io/ingress-nginx"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.chart_version:

``yk8s.k8s-service-layer.ingress.helm.chart_version``
#####################################################

Version of the ingress-nginx Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "4.15.1"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.release_name:

``yk8s.k8s-service-layer.ingress.helm.release_name``
####################################################

The release name inside the cluster for ingress-nginx.


**Type:**::

  non-empty string


**Default:**::

  "ingress"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.release_namespace:

``yk8s.k8s-service-layer.ingress.helm.release_namespace``
#########################################################

The namespace in which to install ingress-nginx.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "k8s-svc-ingress"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values:

``yk8s.k8s-service-layer.ingress.helm.values``
##############################################

Helm values for the ingress-nginx helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml


**Type:**::

  open submodule of (attribute set containing JSON compatible values)


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.allowSnippetAnnotations:

``yk8s.k8s-service-layer.ingress.helm.values.controller.allowSnippetAnnotations``
#################################################################################

Whether to enable snippet annotations.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.extraArgs.enable-ssl-passthrough:

``yk8s.k8s-service-layer.ingress.helm.values.controller.extraArgs.enable-ssl-passthrough``
##########################################################################################

Enable SSL passthrough in the controller


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.replicaCount:

``yk8s.k8s-service-layer.ingress.helm.values.controller.replicaCount``
######################################################################

Replica Count


**Type:**::

  unsigned integer, meaning >=0


**Default:**::

  2


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.resources:

``yk8s.k8s-service-layer.ingress.helm.values.controller.resources``
###################################################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.resources.limits.cpu:

``yk8s.k8s-service-layer.ingress.helm.values.controller.resources.limits.cpu``
##############################################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.resources.limits.memory:

``yk8s.k8s-service-layer.ingress.helm.values.controller.resources.limits.memory``
#################################################################################

Request and limit for the Nginx Ingress controller

**Type:**::

  null or Kubernetes quantity


**Default:**::

  "128Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.resources.requests.cpu:

``yk8s.k8s-service-layer.ingress.helm.values.controller.resources.requests.cpu``
################################################################################

Request and limit for the Nginx Ingress controller

**Type:**::

  null or Kubernetes quantity


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.resources.requests.memory:

``yk8s.k8s-service-layer.ingress.helm.values.controller.resources.requests.memory``
###################################################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or Kubernetes quantity


**Default:**::

  "\${config.yk8s.k8s-service-layer.ingress.helm.values.controller.resources.limits.memory}"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.service.nodePorts.http:

``yk8s.k8s-service-layer.ingress.helm.values.controller.service.nodePorts.http``
################################################################################

Node port for the HTTP endpoint


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  32080


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.service.nodePorts.https:

``yk8s.k8s-service-layer.ingress.helm.values.controller.service.nodePorts.https``
#################################################################################

Node port for the HTTPS endpoint


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  32443


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm.values.controller.service.type:

``yk8s.k8s-service-layer.ingress.helm.values.controller.service.type``
######################################################################

Service type for the frontend Kubernetes service.


**Type:**::

  one of "ClusterIP", "NodePort", "LoadBalancer", "ExternalName"


**Default:**::

  "LoadBalancer"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.install:

``yk8s.k8s-service-layer.ingress.install``
##########################################

If enabled, choose whether to install or uninstall the ingress. IF SET TO
FALSE, THE INGRESS CONTROLLER WILL BE DELETED WITHOUT CHECKING FOR
DISRUPTION.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.scheduling_key:

``yk8s.k8s-service-layer.ingress.scheduling_key``
#################################################

Scheduling key for the cert manager instance and its resources. Has no
default.


**Type:**::

  null or Kubernetes label


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix

