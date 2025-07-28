.. _configuration-options.yk8s.k8s-service-layer.vault:

yk8s.k8s-service-layer.vault
^^^^^^^^^^^^^^^^^^^^^^^^^^^^



.. _configuration-options.yk8s.k8s-service-layer.vault.backup_approle_path:

``yk8s.k8s-service-layer.vault.backup_approle_path``
####################################################



**Type:**::

  Name of a Hashicorp Vault namespace


**Default:**::

  "yaook/vault_v1/approle"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.ca_issuer:

``yk8s.k8s-service-layer.vault.ca_issuer``
##########################################



**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "selfsigned-issuer"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.ca_issuer_kind:

``yk8s.k8s-service-layer.vault.ca_issuer_kind``
###############################################



**Type:**::

  one of "Issuer", "ClusterIssuer"


**Default:**::

  "Issuer"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.chart_version:

``yk8s.k8s-service-layer.vault.chart_version``
##############################################

The helm chart version to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "0.23.0"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.dnsnames:

``yk8s.k8s-service-layer.vault.dnsnames``
#########################################

Extra DNS names for which certificates should be prepared.
NOTE: to work correctly, there must exist an ingress of class `nginx` and it
must allow ssl passthrough.


**Type:**::

  list of RFC1123 subdomain name


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.enable_backups:

``yk8s.k8s-service-layer.vault.enable_backups``
###############################################

If `true`, then an additional backup service will be deployed which creates snapshots and stores
them in an S3 bucket.


**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.enabled:

``yk8s.k8s-service-layer.vault.enabled``
########################################

Whether to enable HashiCorp Vault management.
NOTE: On the first run, the unseal keys and the root token will be printed IN
PLAINTEXT on the ansible output. The unseal keys MUST BE SAVED IN A SECURE
LOCATION to use the Vault instance in the future!
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.external_ingress_class:

``yk8s.k8s-service-layer.vault.external_ingress_class``
#######################################################



**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "nginx"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.external_ingress_issuer_kind:

``yk8s.k8s-service-layer.vault.external_ingress_issuer_kind``
#############################################################

Can be `Issuer` or `ClusterIssuer`, depending on the kind of issuer you would like
to use for externally facing certificates.


**Type:**::

  one of "Issuer", "ClusterIssuer"


**Default:**::

  "ClusterIssuer"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.external_ingress_issuer_name:

``yk8s.k8s-service-layer.vault.external_ingress_issuer_name``
#############################################################

If :ref:`configuration-options.yk8s.k8s-service-layer.vault.ingress` is set to ``true`` and :ref:`configuration-options.yk8s.k8s-service-layer.vault.dnsnames` is not empty, you have to tell the LCM which (Cluster)Issuer to use
for your ACME service.


**Type:**::

  null or RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.helm_repo_url:

``yk8s.k8s-service-layer.vault.helm_repo_url``
##############################################



**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://helm.releases.hashicorp.com"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.ingress:

``yk8s.k8s-service-layer.vault.ingress``
########################################

Whether to enable creation of a publically reachable ingress resource for the API endpoint of vault.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.init_key_shares:

``yk8s.k8s-service-layer.vault.init_key_shares``
################################################

Number of unseal key shares to generate upon vault initialization.
NOTE: On the first run, the unseal keys and the root token will be printed IN
PLAINTEXT on the ansible output. The unseal keys MUST BE SAVED IN A SECURE
LOCATION to use the Vault instance in the future!


**Type:**::

  signed integer


**Default:**::

  5


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.init_key_threshold:

``yk8s.k8s-service-layer.vault.init_key_threshold``
###################################################

Threshold for the Shamir's Secret Sharing Scheme used for unsealing, i.e. the
number of shares required to unseal the vault after a restart
NOTE: On the first run, the unseal keys and the root token will be printed IN
PLAINTEXT on the ansible output. The unseal keys MUST BE SAVED IN A SECURE
LOCATION to use the Vault instance in the future!


**Type:**::

  signed integer


**Default:**::

  2


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.management_cluster_integration:

``yk8s.k8s-service-layer.vault.management_cluster_integration``
###############################################################

Whether to enable management cluster integration.
If set to true, the Vault is configured to be exposed via yaook/operator
infra-ironic, that is, via the integrated DNSmasq to all nodes associated.
The default is false. This can be enabled in non-infra-ironic clusters,
without significant damage.
NOTE: To work in infra-ironic clusters, this requires the vault to be in the
same namespace as the infra-ironic instance.
NOTE: if you enable this, you MUST NOT set the service_type to ClusterIP; it
will default to NodePort and it must be at least NodePort or LoadBalancer for
the integration to work correctly.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.namespace:

``yk8s.k8s-service-layer.vault.namespace``
##########################################

Namespace to deploy the vault in (will be created if it does not exist, but
ever deleted).


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "k8s-svc-vault"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.s3_config_file:

``yk8s.k8s-service-layer.vault.s3_config_file``
###############################################

Credentials to access an S3 bucket to which the backups will be written. Required if :ref:`configuration-options.yk8s.k8s-service-layer.vault.enable_backups` is set to ``true``
You can find a template in `managed-k8s/templates/vault_backup_s3_config.template.yaml`.

Note: The given path is interpreted as being relative to the cluster repo's config directory.


**Type:**::

  null or Relative POSIX path (without special '.' and '..')


**Default:**::

  null


**Example:**::

  "./vault/backup_s3_config.yaml"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.scheduling_key:

``yk8s.k8s-service-layer.vault.scheduling_key``
###############################################

Scheduling key for the vault instance and its resources. Has no default.


**Type:**::

  null or Kubernetes label


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.service_active_node_port:

``yk8s.k8s-service-layer.vault.service_active_node_port``
#########################################################

Node port to use for the Service which exposes the active Vault instance
See NOTE above regarding exposure of the Vault.


**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  32048


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.service_type:

``yk8s.k8s-service-layer.vault.service_type``
#############################################

Type of the Kubernetes Service of the Vault
NOTE: You may set this to LoadBalancer, but note that this will still use the internal certificate.
If you want to expose the Vault to the outside world, use the ingress config above.


**Type:**::

  one of "ClusterIP", "NodePort", "LoadBalancer", "ExternalName"


**Default:**::

  "ClusterIP"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.storage_class:

``yk8s.k8s-service-layer.vault.storage_class``
##############################################

Storage class for the vault file storage backend.


**Type:**::

  RFC1123 subdomain name (lowercase) or RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "csi-sc-cinderplugin"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix


.. _configuration-options.yk8s.k8s-service-layer.vault.storage_size:

``yk8s.k8s-service-layer.vault.storage_size``
#############################################

Storage size for the vault file storage backend.


**Type:**::

  Kubernetes quantity


**Default:**::

  "8Gi"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/k8s-supplements/vault.nix

