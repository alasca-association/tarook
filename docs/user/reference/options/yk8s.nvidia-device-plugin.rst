.. _configuration-options.yk8s.nvidia-device-plugin:

yk8s.nvidia-device-plugin
^^^^^^^^^^^^^^^^^^^^^^^^^



.. _configuration-options.yk8s.nvidia-device-plugin.device_plugin_chart_ref:

``yk8s.nvidia-device-plugin.device_plugin_chart_ref``
#####################################################

Helm chart reference for the NVIDIA device plugin.
Note that the NVIDIA device plugin is only installed
if at least one GPU node is detected and uninstalled
otherwise!


**Type:**::

  non-empty string


**Default:**::

  "nvdp/nvidia-device-plugin"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/nvidia-device-plugin.nix


.. _configuration-options.yk8s.nvidia-device-plugin.device_plugin_chart_version:

``yk8s.nvidia-device-plugin.device_plugin_chart_version``
#########################################################

Helm chart version for the NVIDIA device plugin.
Note that the NVIDIA device plugin is only installed
if at least one GPU node is detected and uninstalled
otherwise!


**Type:**::

  string


**Default:**::

  "0.17.0"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/nvidia-device-plugin.nix


.. _configuration-options.yk8s.nvidia-device-plugin.device_plugin_helm_repo_url:

``yk8s.nvidia-device-plugin.device_plugin_helm_repo_url``
#########################################################

Helm repository URL for the NVIDIA device plugin.
Note that the NVIDIA device plugin is only installed
if at least one GPU node is detected and uninstalled
otherwise!


**Type:**::

  string


**Default:**::

  "https://nvidia.github.io/k8s-device-plugin"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/nvidia-device-plugin.nix


.. _configuration-options.yk8s.nvidia-device-plugin.device_plugin_namespace:

``yk8s.nvidia-device-plugin.device_plugin_namespace``
#####################################################

Namespace into which the NVIDIA device plugin will get deployed.
Note that the NVIDIA device plugin is only installed
if at least one GPU node is detected and uninstalled
otherwise!


**Type:**::

  non-empty string


**Default:**::

  "k8s-nvidia-device-plugin"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/nvidia-device-plugin.nix

