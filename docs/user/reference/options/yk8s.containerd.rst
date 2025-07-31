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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/containerd.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/containerd.nix


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
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/containerd.nix

