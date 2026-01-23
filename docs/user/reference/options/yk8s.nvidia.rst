.. _configuration-options.yk8s.nvidia:

yk8s.nvidia
^^^^^^^^^^^



.. _configuration-options.yk8s.nvidia.device_plugin.helm.chart_ref:

``yk8s.nvidia.device_plugin.helm.chart_ref``
############################################

The chart reference (relative to the repository) of the nvidia device plugin Helm chart.


**Type:**::

  RFC3986 relative URL path


**Default:**::

  "nvidia-device-plugin"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/nvidia.nix


.. _configuration-options.yk8s.nvidia.device_plugin.helm.chart_repo_url:

``yk8s.nvidia.device_plugin.helm.chart_repo_url``
#################################################

The URL to the Helm repository for the nvidia device plugin Helm chart.


**Type:**::

  RFC3986 HTTP(S) URL


**Default:**::

  "https://nvidia.github.io/k8s-device-plugin"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/nvidia.nix


.. _configuration-options.yk8s.nvidia.device_plugin.helm.chart_version:

``yk8s.nvidia.device_plugin.helm.chart_version``
################################################

Version of the nvidia device plugin Helm chart to be used.

If the version shall be unpinned, set to: ``null``.


**Type:**::

  null or Helm chart version (Semantic version 2 string or OCI image tag)


**Default:**::

  "0.18.2"


**Example:**::

  "1.2.3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/nvidia.nix


.. _configuration-options.yk8s.nvidia.device_plugin.helm.release_name:

``yk8s.nvidia.device_plugin.helm.release_name``
###############################################

The release name inside the cluster for nvidia device plugin.


**Type:**::

  non-empty string


**Default:**::

  "nvdp"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/nvidia.nix


.. _configuration-options.yk8s.nvidia.device_plugin.helm.release_namespace:

``yk8s.nvidia.device_plugin.helm.release_namespace``
####################################################

The namespace in which to install nvidia device plugin.


**Type:**::

  RFC1123 subdomain label (lowercase) or RFC1035 subdomain label (lowercase)


**Default:**::

  "k8s-nvidia-device-plugin"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/nvidia.nix


.. _configuration-options.yk8s.nvidia.device_plugin.helm.values:

``yk8s.nvidia.device_plugin.helm.values``
#########################################

Helm values for the nvidia device plugin helm chart.

Some values are set by default through Tarook, but arbitrary values can be set.
For a full list of possible values, see
https://github.com/NVIDIA/k8s-device-plugin/blob/main/deployments/helm/nvidia-device-plugin/values.yaml


**Type:**::

  JSON value


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/nvidia.nix


.. _configuration-options.yk8s.nvidia.vgpu.driver_blob_url:

``yk8s.nvidia.vgpu.driver_blob_url``
####################################

Should point to a object store or otherwise web server, where the vGPU Manager installation file is available.


**Type:**::

  RFC3986 HTTP(S) URL or RFC3986 (S)FTP URL


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/nvidia.nix


.. _configuration-options.yk8s.nvidia.vgpu.manager_filename:

``yk8s.nvidia.vgpu.manager_filename``
#####################################

Should hold the name of the vGPU Manager installation file.


**Type:**::

  POSIX file name


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/nvidia.nix

