.. _configuration-options.yk8s.kubernetes:

yk8s.kubernetes
^^^^^^^^^^^^^^^


This section contains generic information about the Kubernetes cluster
configuration.

.. _configuration-options.yk8s.kubernetes.apiserver.audit_logs.enabled:

``yk8s.kubernetes.apiserver.audit_logs.enabled``
################################################

Whether to enable audit logs for the kube-apiserver.

If enabled, a policy file is mounted to the kube-apiserver.
The policy file can be adjusted via
:ref:`configuration-options.yk8s.kubernetes.apiserver.audit_logs.policy`.
Logs are written to ``/var/log/kubernetes/audit/audit.log``.
The ``audit-log-maxage`` and ``audit-log-maxbackup`` settings are
currently hardcoded to ``1``.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.apiserver.audit_logs.max_size:

``yk8s.kubernetes.apiserver.audit_logs.max_size``
#################################################

Maximum size of apiserver audit log files in megabytes before it gets rotated


**Type:**::

  unsigned integer, meaning >=0


**Default:**::

  50


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.apiserver.audit_logs.policy:

``yk8s.kubernetes.apiserver.audit_logs.policy``
###############################################

The audit policy for the kube-apiserver.
Checkout the
`Kubernetes Auditing Documentation <https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/#audit-policy>`_
for further information on how to configure.

You may use ``audit_logs.policy = yk8s-lib.importYAML ./path/to/policy.yaml;`` to import
an existing policy manifest. Note that the YAML file has to be added to the git repository
in order to be evaluated by Nix.

Alternatively, if you prefer to specify the policy in Nix directly, you may use
https://github.com/cloudandheat/json2nix to convert existing policies to Nix.

Note that this option is not type checked by Nix, so make sure that it it's a valid audit policy.


**Type:**::

  JSON value


**Default:**::

  {
    apiVersion = "audit.k8s.io/v1";
    kind = "Policy";
    # Don't generate audit events for all requests in RequestReceived stage.
    # Use union of both if omitStages is also defined in rules.
    omitStages = [
      "RequestReceived"
    ];
    omitManagedFields = true;
    rules = [
      # Audit profile from Google Container-Optimized OS
      # https://github.com/kubernetes/kubernetes/blob/cacd595bae429e5739edaf02c6915e9c5731dea7/cluster/gce/gci/configure-helper.sh#L1227C1-L1232C18
      # Don't log events with no relevance for us and which happen very often
  
      # Don't log these read-only URLs.
      {
        level = "None"; # The first matching rule sets the audit level of the event
        nonResourceURLs = [
          "/healthz*"
          "/readyz" # We had maaaaaany of those with code 200
          "/" # Had many of those, too, by user system:anonymous with HTTP 403
          "/livez" # Here, too
          "/version"
          "/swagger*"
        ];
      }
  
      # Don't log events requests because of performance impact.
      {
        level = "None";
        resources = [
          {
            group = ""; # core
            resources = [
              "events"
            ];
          }
        ];
      }
  
      {
        level = "Request";
        users = [
          "kubelet"
          "system:node-problem-detector"
          "system:serviceaccount:kube-system:node-problem-detector"
        ];
        verbs = [
          "update"
          "patch"
        ];
        resources = [
          {
            group = ""; # core
            resources = [
              "nodes/status"
              "pods/status"
            ];
          }
        ];
        omitStages = [
          "RequestReceived"
        ];
      }
      {
        level = "Request";
        userGroups = [
          "system:nodes"
        ];
        verbs = [
          "update"
          "patch"
        ];
        resources = [
          {
            group = "";
            resources = [
              "nodes/status"
              "pods/status"
            ];
          }
        ];
        omitStages = [
          "RequestReceived"
        ];
      }
  
      # deletecollection calls can be large, don't log responses for expected namespace deletions
      {
        level = "Request";
        users = [
          "system:serviceaccount:kube-system:namespace-controller"
        ];
        verbs = [
          "deletecollection"
        ];
        omitStages = [
          "RequestReceived"
        ];
      }
  
      # Secrets, ConfigMaps, TokenRequest and TokenReviews can contain sensitive & binary data,
      # so only log at the Metadata level.
      {
        level = "Metadata";
        resources = [
          {
            group = ""; # core
            resources = [
              "secrets"
              "configmaps"
              "serviceaccounts/token"
            ];
          }
          {
            group = "authentication.k8s.io";
            resources = [
              "tokenreviews"
            ];
          }
        ];
        omitStages = [
          "RequestReceived"
        ];
      }
  
      # Get responses can be large; skip them.
      {
        level = "Request";
        verbs = [
          "get"
          "list"
          "watch"
        ];
        resources = [
          {group = "";} # core
          {group = "admissionregistration.k8s.io";}
          {group = "apiextensions.k8s.io";}
          {group = "apiregistration.k8s.io";}
          {group = "apps";}
          {group = "authentication.k8s.io";}
          {group = "authorization.k8s.io";}
          {group = "autoscaling";}
          {group = "batch";}
          {group = "certificates.k8s.io";}
          {group = "extensions";}
          {group = "metrics.k8s.io";}
          {group = "networking.k8s.io";}
          {group = "node.k8s.io";}
          {group = "policy";}
          {group = "rbac.authorization.k8s.io";}
          {group = "scheduling.k8s.io";}
          {group = "storage.k8s.io";}
        ];
        omitStages = [
          "RequestReceived"
        ];
      }
      # Default level for known APIs
      {
        level = "Request";
        resources = [
          {group = "";} # core
          {group = "admissionregistration.k8s.io";}
          {group = "apiextensions.k8s.io";}
          {group = "apiregistration.k8s.io";}
          {group = "apps";}
          {group = "authentication.k8s.io";}
          {group = "authorization.k8s.io";}
          {group = "autoscaling";}
          {group = "batch";}
          {group = "certificates.k8s.io";}
          {group = "extensions";}
          {group = "metrics.k8s.io";}
          {group = "networking.k8s.io";}
          {group = "node.k8s.io";}
          {group = "policy";}
          {group = "rbac.authorization.k8s.io";}
          {group = "scheduling.k8s.io";}
          {group = "storage.k8s.io";}
        ];
        omitStages = [
          "RequestReceived"
        ];
      }
      # Default level for all other requests.
      {
        level = "Metadata";
        omitStages = [
          "RequestReceived"
        ];
      }
    ];
    # End of audit profile for Google Container-Optimized OS
  }
  


**Example:**::

  yk8s-lib.importYAML ./path/to/policy.yaml # Note that the file has to be added to the git repository to be evaluated by Nix
  


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.apiserver.frontend_port:

``yk8s.kubernetes.apiserver.frontend_port``
###########################################



**Type:**::

  16 bit unsigned integer; between 0 and 65535 (both inclusive)


**Default:**::

  8888


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.apiserver.memory_limit:

``yk8s.kubernetes.apiserver.memory_limit``
##########################################

Memory resources limit for the apiserver.

.. note::

  Modifications to this setting only apply on an upgrade of Kubernetes.

**Type:**::

  null or Kubernetes quantity


**Default:**::

  null


**Example:**::

  "1Gi"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.controller_manager.enable_signing_requests:

``yk8s.kubernetes.controller_manager.enable_signing_requests``
##############################################################

Whether to enable signing requests.

Note: This currently means that the cluster CA key is copied to the control
plane nodes which decreases security compared to storing the CA only in the Vault.
IMPORTANT: Manual steps required when enabled after cluster creation
The CA key is made available through Vault's kv store and fetched by Ansible.
Due to Vault's security architecture this means
you must run the CA rotation script
(or manually upload the CA key from your backup to Vault's kv store).
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.controller_manager.large_cluster_size_threshold:

``yk8s.kubernetes.controller_manager.large_cluster_size_threshold``
###################################################################



**Type:**::

  32 bit unsigned integer; between 0 and 4294967295 (both inclusive)


**Default:**::

  50


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.is_gpu_cluster:

``yk8s.kubernetes.is_gpu_cluster``
##################################

Set this variable if this cluster contains worker with GPU access
and you want to make use of these inside of the cluster,
so that the driver and surrounding framework is deployed.


**Type:**::

  boolean


**Default:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.monitoring.enabled:

``yk8s.kubernetes.monitoring.enabled``
######################################

Whether to enable Prometheus-based monitoring.
For prometheus-specific configurations take a look at the config options in
:ref:`configuration-options.yk8s.k8s-service-layer.prometheus`.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes/monitoring.nix


.. _configuration-options.yk8s.kubernetes.storage.nodeplugin_toleration:

``yk8s.kubernetes.storage.nodeplugin_toleration``
#################################################

Whether to enable nodeplugin toleration.
Setting this to true will cause the storage plugins
to run on all nodes (ignoring all taints). This is often desirable.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.version:

``yk8s.kubernetes.version``
###########################

Kubernetes version


**Type:**::

  Kubernetes version (one of: 1.31.x, 1.32.x, 1.33.x)


**Default:**::

  "1.33.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes


.. _configuration-options.yk8s.kubernetes.virtualize_gpu:

``yk8s.kubernetes.virtualize_gpu``
##################################

Whether to enable virtualization of Nvidia GPUs on worker nodes.
Set this variable to virtualize Nvidia GPUs on worker nodes
for usage outside of the Kubernetes cluster / above the Kubernetes layer.
It will install a VGPU manager on the worker node and
split the GPU according to chosen vgpu type.
Note: This will not install Nvidia drivers to utilize vGPU guest VMs!!
If set to true, please set further variables in :ref:`configuration-options.yk8s.miscellaneous`.
Note: This is mutually exclusive with :ref:`configuration-options.yk8s.kubernetes.is_gpu_cluster`.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/kubernetes

