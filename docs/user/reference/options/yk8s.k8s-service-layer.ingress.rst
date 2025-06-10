.. _configuration-options.yk8s.k8s-service-layer.ingress:

yk8s.k8s-service-layer.ingress
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


The used NGINX ingress controller setup will be explained in more detail
soon :)

.. note::

  To enable an ingress controller,
  ``k8s-service-layer.ingress.enabled`` needs to be set to ``true``.

.. _configuration-options.yk8s.k8s-service-layer.ingress.allow_snippet_annotations:

``yk8s.k8s-service-layer.ingress.allow_snippet_annotations``
############################################################

Whether to enable snippet annotations.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.chart_ref:

``yk8s.k8s-service-layer.ingress.chart_ref``
############################################



**Type:**::

  non-empty string


**Default:**::

  "ingress-nginx/ingress-nginx"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.chart_version:

``yk8s.k8s-service-layer.ingress.chart_version``
################################################



**Type:**::

  non-empty string


**Default:**::

  "4.12.3"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.enable_ssl_passthrough:

``yk8s.k8s-service-layer.ingress.enable_ssl_passthrough``
#########################################################

Enable SSL passthrough in the controller


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.helm_repo_url:

``yk8s.k8s-service-layer.ingress.helm_repo_url``
################################################



**Type:**::

  non-empty string


**Default:**::

  "https://kubernetes.github.io/ingress-nginx"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.namespace:

``yk8s.k8s-service-layer.ingress.namespace``
############################################

Namespace to deploy the ingress in (will be created if it does not exist, but
never deleted).


**Type:**::

  non-empty string


**Default:**::

  "k8s-svc-ingress"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.nodeport_http:

``yk8s.k8s-service-layer.ingress.nodeport_http``
################################################

Node port for the HTTP endpoint


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  32080


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.nodeport_https:

``yk8s.k8s-service-layer.ingress.nodeport_https``
#################################################

Node port for the HTTPS endpoint


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  32443


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.release_name:

``yk8s.k8s-service-layer.ingress.release_name``
###############################################



**Type:**::

  non-empty string


**Default:**::

  "ingress"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.replica_count:

``yk8s.k8s-service-layer.ingress.replica_count``
################################################

Replica Count


**Type:**::

  positive integer, meaning >0


**Default:**::

  2


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.resources:

``yk8s.k8s-service-layer.ingress.resources``
############################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.resources.limits.cpu:

``yk8s.k8s-service-layer.ingress.resources.limits.cpu``
#######################################################

CPU limits should never be set.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.resources.limits.memory:

``yk8s.k8s-service-layer.ingress.resources.limits.memory``
##########################################################

Request and limit for the Nginx Ingress controller

**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "128Mi"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.resources.requests.cpu:

``yk8s.k8s-service-layer.ingress.resources.requests.cpu``
#########################################################

Request and limit for the Nginx Ingress controller

**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "100m"


**Example:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.resources.requests.memory:

``yk8s.k8s-service-layer.ingress.resources.requests.memory``
############################################################

Memory requests should always be equal to the limits.

Thus, this option is deprecated.


**Type:**::

  null or string matching the pattern ^(((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))((Ki|Mi|Gi|Ti|Pi|Ei)|(e((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+)))|E((([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))|([+-])(([0-9]+)|([0-9]+)[.]([0-9]+)|([0-9]+)[.]|[.]([0-9]+))))|(m|k|M|G|T|P|E)?))$


**Default:**::

  "\${config.yk8s.k8s-service-layer.ingress.resources.limits.memory}"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.scheduling_key:

``yk8s.k8s-service-layer.ingress.scheduling_key``
#################################################

Scheduling key for the cert manager instance and its resources. Has no
default.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix


.. _configuration-options.yk8s.k8s-service-layer.ingress.service_type:

``yk8s.k8s-service-layer.ingress.service_type``
###############################################

Service type for the frontend Kubernetes service.


**Type:**::

  one of "ClusterIP", "NodePort", "LoadBalancer", "ExternalName"


**Default:**::

  "LoadBalancer"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/ingress.nix

