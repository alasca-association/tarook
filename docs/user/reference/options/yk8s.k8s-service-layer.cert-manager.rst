.. _configuration-options.yk8s.k8s-service-layer.cert-manager:

yk8s.k8s-service-layer.cert-manager
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


The used Cert-Manager controller setup will be explained in more detail
soon :)

  .. note::

      To enable cert-manager,
      :ref:`configuration-options.yk8s.k8s-service-layer.cert-manager.enabled`
      needs to be set to ``true``.

.. _configuration-options.yk8s.k8s-service-layer.cert-manager.chart_ref:

``yk8s.k8s-service-layer.cert-manager.chart_ref``
#################################################



**Type:**::

  RFC3986 relative URL path


**Default:**::

  "cert-manager"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.chart_version:

``yk8s.k8s-service-layer.cert-manager.chart_version``
#####################################################

The helm chart version to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "1.18.2"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.enabled:

``yk8s.k8s-service-layer.cert-manager.enabled``
###############################################

Whether to enable management of a cert-manager.io instance.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.helm_repo_url:

``yk8s.k8s-service-layer.cert-manager.helm_repo_url``
#####################################################



**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://charts.jetstack.io"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.install:

``yk8s.k8s-service-layer.cert-manager.install``
###############################################

Install or uninstall cert manager. If set to false, the cert-manager will be
uninstalled WITHOUT CHECK FOR DISRUPTION!


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.letsencrypt_email:

``yk8s.k8s-service-layer.cert-manager.letsencrypt_email``
#########################################################

If given, a *cluster wide* Let's Encrypt issuer with that email address will
be generated. Requires an ingress to work correctly.
DO NOT ENABLE THIS IN CUSTOMER CLUSTERS, BECAUSE THEY SHOULD NOT CREATE
CERTIFICATES UNDER OUR NAME. Customers are supposed to deploy their own
ACME/Let's Encrypt issuer.


**Type:**::

  null or RFC5322 email address


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.letsencrypt_ingress:

``yk8s.k8s-service-layer.cert-manager.letsencrypt_ingress``
###########################################################

The ingress class to use for responding to the ACME challenge.
The default value works for the default k8s-service-layer.ingress
configuration and may need to be adapted in case a different ingress is to be
used.


**Type:**::

  non-empty string


**Default:**::

  "nginx"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.letsencrypt_preferred_chain:

``yk8s.k8s-service-layer.cert-manager.letsencrypt_preferred_chain``
###################################################################

By default, the ACME issuer will let the server choose the certificate chain
to use for the certificate. This can be used to override it.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.letsencrypt_server:

``yk8s.k8s-service-layer.cert-manager.letsencrypt_server``
##########################################################

This variable let's you specify the endpoint of the ACME issuer. A common usecase
is to switch between staging and production.
See https://letsencrypt.org/docs/staging-environment/


**Type:**::

  RFC3986 HTTP(S) URL (scheme, authority and path only)


**Default:**::

  "https://acme-v02.api.letsencrypt.org/directory"


**Example:**::

  "https://acme-staging-v02.api.letsencrypt.org/directory"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.namespace:

``yk8s.k8s-service-layer.cert-manager.namespace``
#################################################

Configure in which namespace the cert-manager is run. The namespace is
created automatically, but never deleted automatically.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "k8s-svc-cert-manager"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.release_name:

``yk8s.k8s-service-layer.cert-manager.release_name``
####################################################



**Type:**::

  Helm chart release name


**Default:**::

  "cert-manager"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix


.. _configuration-options.yk8s.k8s-service-layer.cert-manager.scheduling_key:

``yk8s.k8s-service-layer.cert-manager.scheduling_key``
######################################################

Scheduling key for the cert manager instance and its resources. Has no
default.


**Type:**::

  null or Kubernetes label


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/k8s-supplements/cert-manager.nix

