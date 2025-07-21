.. _configuration-options.yk8s.miscellaneous:

yk8s.miscellaneous
^^^^^^^^^^^^^^^^^^


This section contains various configuration options for special use
cases. You won’t need to enable and adjust any of these under normal
circumstances.

.. _configuration-options.yk8s.miscellaneous.apt_proxy_url:

``yk8s.miscellaneous.apt_proxy_url``
####################################

APT Proxy Configuration
As a secondary effect, https repositories are not used, since
those don't work with caching proxies like apt-cacher-ng.


**Type:**::

  null or RFC3986 HTTP URL (scheme, authority and path only)


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix


.. _configuration-options.yk8s.miscellaneous.cluster_behind_proxy:

``yk8s.miscellaneous.cluster_behind_proxy``
###########################################

Whether to enable the cluster will be placed behind a HTTP proxy.
If unconfigured images will be used to setup the cluster, the updates of
package sources, the download of docker images and the initial cluster setup will fail.
NOTE: These chances are currently only tested for Debian-based operating systems and not for RHEL-based!
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix


.. _configuration-options.yk8s.miscellaneous.custom_chrony_configuration:

``yk8s.miscellaneous.custom_chrony_configuration``
##################################################

Whether to enable custom Chrony configration
The ntp servers used by chrony can be customized if it should be necessary or wanted.
A list of pools and/or servers can be specified.
Chrony treats both similarily but it expects that a pool will resolve to several ntp servers.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix


.. _configuration-options.yk8s.miscellaneous.custom_ntp_pools:

``yk8s.miscellaneous.custom_ntp_pools``
#######################################

A list of NTP pools.


**Type:**::

  list of (IPv4 address in four-octets decimal notation or IPv6 address in colon-hexadecimal notation or RFC1123 subdomain name)


**Default:**::

  [ ]


**Example:**::

  [
    "0.pool.ntp.example.org"
    "1.pool.ntp.example.org"
  ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix


.. _configuration-options.yk8s.miscellaneous.custom_ntp_servers:

``yk8s.miscellaneous.custom_ntp_servers``
#########################################

A list of NTP servers.


**Type:**::

  list of (IPv4 address in four-octets decimal notation or IPv6 address in colon-hexadecimal notation or RFC1123 subdomain name)


**Default:**::

  [ ]


**Example:**::

  [
    "0.server.ntp.example.org"
    "1.server.ntp.example.org"
  ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix


.. _configuration-options.yk8s.miscellaneous.http_proxy:

``yk8s.miscellaneous.http_proxy``
#################################

Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
internal docker repositories can be added to the :ref:`configuration-options.yk8s.miscellaneous.no_proxy` config entry
Important note: Settings for the yaook-k8s cluster itself (like the service subnet or the pod subnet)
will be set automagically and do not have to set manually here.


**Type:**::

  null or RFC3986 HTTP URL (scheme, authority and path only)


**Default:**::

  null


**Example:**::

  "http://proxy.example.com:8889"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix


.. _configuration-options.yk8s.miscellaneous.https_proxy:

``yk8s.miscellaneous.https_proxy``
##################################

Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
internal docker repositories can be added to the :ref:`configuration-options.yk8s.miscellaneous.no_proxy` config entry
Important note: Settings for the yaook-k8s cluster itself (like the service subnet or the pod subnet)
will be set automagically and do not have to set manually here.


**Type:**::

  null or RFC3986 HTTPS URL (scheme, authority and path only)


**Default:**::

  null


**Example:**::

  "https://proxy.example.com:8889"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix


.. _configuration-options.yk8s.miscellaneous.no_proxy:

``yk8s.miscellaneous.no_proxy``
###############################

Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
internal docker repositories can be added to the :ref:`configuration-options.yk8s.miscellaneous.no_proxy` config entry
Important note: Settings for the yaook-k8s cluster itself (like the service subnet or the pod subnet)
will be set automagically and do not have to set manually here.


**Type:**::

  null or (list of (IPv4 address in four-octets decimal notation or IPv4 address in four-octets decimal notation plus subnet in CIDR notation or RFC1123 subdomain name))


**Default:**::

  [ ]


**Example:**::

  [
    "localhost"
    "127.0.0.0/8"
  ]


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix


.. _configuration-options.yk8s.miscellaneous.vm_max_map_count:

``yk8s.miscellaneous.vm_max_map_count``
#######################################

Value for the kernel parameter `vm.max_map_count` on k8s nodes. Modifications
might be required depending on the software running on the nodes (e.g., ElasticSearch).
If you leave the value commented out you're fine and the system's default will be kept.


**Type:**::

  signed integer


**Default:**::

  262144


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/miscellaneous.nix

