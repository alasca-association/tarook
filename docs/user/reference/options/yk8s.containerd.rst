.. _configuration-options.yk8s.containerd:

yk8s.containerd
^^^^^^^^^^^^^^^



.. _configuration-options.yk8s.containerd.mirrors:

``yk8s.containerd.mirrors``
###########################

Registry mirrors which will be configured for containerd.
These can act as pull through cache to reduce external network traffic
and the amount of pulls from registries which have rate limits.
The upstream registry will automatically be used after all defined hosts have been tried.


**Type:**::

  list of (submodule)


**Default:**::

  [ ]


**Example:**::

  [
    {
      mirrors = [
        "https://registry-cache-1.example.com"
        "https://registry-cache-2.example.com:5000"
      ];
      registry = "docker.io";
    }
    {
      mirrors = [
        "https://registry-cache-3.example.com"
      ];
      registry = "some.container.registry";
    }
    {
      mirrors = [
        "https://registry-cache-4.example.com"
      ];
      registry = null;
    }
  ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/containerd.nix


.. _configuration-options.yk8s.containerd.mirrors.*.mirrors:

``yk8s.containerd.mirrors.*.mirrors``
#####################################

A list of URLs which should be substituted for the registry.
Optionally specify a port.


**Type:**::

  list of RFC3986 HTTPS URL (scheme, authority and path only)


**Example:**::

  [
    "https://registry-1.example.com"
    "https://registry-2.example.com:5000"
  ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/containerd.nix


.. _configuration-options.yk8s.containerd.mirrors.*.registry:

``yk8s.containerd.mirrors.*.registry``
######################################

Name of the registry host for which the mirrors should be used.
Registry hosts are typically referred to by their internet domain names, aka. registry host names.
For example, docker.io, quay.io, gcr.io, and ghcr.io.
Set to null if the mirrors should be used as default.


**Type:**::

  null or RFC1123 subdomain name


**Example:**::

  "gcr.io"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/containerd.nix


.. _configuration-options.yk8s.containerd.version:

``yk8s.containerd.version``
###########################

The containerd version to be deployed on Kubernetes nodes.

Changes to this option only directly affect newly provisioned Kubernetes nodes.
To adjust the containerd version on **all** Kubernetes nodes,
either do a :doc:`Kubernetes upgrade </user/guide/kubernetes/upgrading-kubernetes>`,
update the OS packages on all nodes via
:ref:`update-kubernetes-nodes.sh<actions-references.update-kubernetes-nodessh>`,
or, if you are brave, run:

.. warning::

   This is potentially disruptive.

.. code:: console

   $ MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-k8s-core.sh prepare-k8s-nodes.yaml

.. note::

  Changes to this option potentially downgrades containerd.


**Type:**::

  Semantic version 2 string


**Default:**::

  "2.1.5"


**Example:**::

  "2.2.1"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/containerd.nix

