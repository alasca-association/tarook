.. _configuration-options.yk8s.infra:

yk8s.infra
^^^^^^^^^^


This section contains various configuration options necessary for all
cluster types, Terraform and bare-metal based.

.. _configuration-options.yk8s.infra.ansible_hosts:

``yk8s.infra.ansible_hosts``
############################

Entries to the Ansible hosts file. Will be rendered to a YAML-based file into the inventory.
This option is mandatory for bare-metal clusters and is automatically managed if Terraform is used.

Check the parts regarding YAML in the Ansible documentation: https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html


**Type:**::

  null or (attribute set of (submodule))


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ansible_hosts.<name>.children:

``yk8s.infra.ansible_hosts.<name>.children``
############################################



**Type:**::

  attribute set of (submodule)


**Default:**::

  { }


**Declared by**


.. _configuration-options.yk8s.infra.ansible_hosts.<name>.hosts:

``yk8s.infra.ansible_hosts.<name>.hosts``
#########################################



**Type:**::

  attribute set of (JSON value)


**Default:**::

  { }


**Declared by**


.. _configuration-options.yk8s.infra.ansible_hosts.<name>.hosts.<name>.ansible_host:

``yk8s.infra.ansible_hosts.<name>.hosts.<name>.ansible_host``
#############################################################



**Type:**::

  null or IPv4 address in four-octets decimal notation or IPv6 address in colon-hexadecimal notation or RFC1123 subdomain name


**Default:**::

  null


**Declared by**


.. _configuration-options.yk8s.infra.ansible_hosts.<name>.hosts.<name>.local_ipv4_address:

``yk8s.infra.ansible_hosts.<name>.hosts.<name>.local_ipv4_address``
###################################################################



**Type:**::

  null or IPv4 address in four-octets decimal notation


**Default:**::

  null


**Declared by**


.. _configuration-options.yk8s.infra.ansible_hosts.<name>.hosts.<name>.local_ipv6_address:

``yk8s.infra.ansible_hosts.<name>.hosts.<name>.local_ipv6_address``
###################################################################



**Type:**::

  null or IPv6 address in colon-hexadecimal notation


**Default:**::

  null


**Declared by**


.. _configuration-options.yk8s.infra.ansible_hosts.<name>.vars:

``yk8s.infra.ansible_hosts.<name>.vars``
########################################



**Type:**::

  attribute set of (JSON value)


**Default:**::

  { }


**Declared by**


.. _configuration-options.yk8s.infra.ansible_hosts.all.vars.ansible_python_interpreter:

``yk8s.infra.ansible_hosts.all.vars.ansible_python_interpreter``
################################################################



**Type:**::

  Absolute POSIX path (without special '.' and '..')


**Default:**::

  "/usr/bin/python3"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ansible_hosts.frontend:

``yk8s.infra.ansible_hosts.frontend``
#####################################



**Type:**::

  submodule


**Default:**::

  {
    children = {
      gateways = { };
    };
  }


**Example:**::

  {
    children = {
      masters = { };
    };
  }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ansible_hosts.gateways:

``yk8s.infra.ansible_hosts.gateways``
#####################################



**Type:**::

  submodule


**Default:**::

  { }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ansible_hosts.masters:

``yk8s.infra.ansible_hosts.masters``
####################################



**Type:**::

  submodule


**Example:**::

  {
    hosts = {
      devcluster-master-1 = {
        ansible_host = "172.30.154.66";
        local_ipv4_address = "172.30.154.66";
      };
    };
  }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ansible_hosts.orchestrator:

``yk8s.infra.ansible_hosts.orchestrator``
#########################################



**Type:**::

  submodule


**Default:**::

  {
    hosts = {
      localhost = {
        ansible_connection = "local";
        ansible_python_interpreter = "{{ ansible_playbook_python }}";
      };
    };
  }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ansible_hosts.workers:

``yk8s.infra.ansible_hosts.workers``
####################################



**Type:**::

  submodule


**Default:**::

  { }


**Example:**::

  {
    hosts = {
      devcluster-worker-1 = {
        ansible_host = "172.30.154.99";
        local_ipv4_address = "172.30.154.99";
      };
    };
  }


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.cluster_name:

``yk8s.infra.cluster_name``
###########################

Name of the cluster that is to be build and managed.

Used to distinguish the cluster from others
and to name harbour infrastructure resources.


**Type:**::

  non-empty string without spaces


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.hosts_file:

``yk8s.infra.hosts_file``
#########################

A custom hosts file. This option is deprecated. Use :ref:`configuration-options.yk8s.infra.ansible_hosts` instead.


**Type:**::

  null or path in the Nix store


**Default:**::

  null


**Example:**::

  ./hosts


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ipv4_enabled:

``yk8s.infra.ipv4_enabled``
###########################

Whether to enable IPv4.

**Type:**::

  boolean


**Default:**::

  true


**Example:**::

  false


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.ipv6_enabled:

``yk8s.infra.ipv6_enabled``
###########################

Whether to enable IPv6.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.networking_fixed_ip:

``yk8s.infra.networking_fixed_ip``
##################################



**Type:**::

  null or IPv4 address in four-octets decimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.networking_fixed_ip_v6:

``yk8s.infra.networking_fixed_ip_v6``
#####################################



**Type:**::

  null or IPv6 address in colon-hexadecimal notation


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.subnet_cidr:

``yk8s.infra.subnet_cidr``
##########################

The IPv4 CIDR of the internally used network.
Only applies if :ref:`configuration-options.yk8s.infra.ipv4_enabled` is set to ``true``.


**Type:**::

  IPv4 address in four-octets decimal notation plus subnet in CIDR notation


**Default:**::

  "172.30.154.0/24"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix


.. _configuration-options.yk8s.infra.subnet_v6_cidr:

``yk8s.infra.subnet_v6_cidr``
#############################

The IPv6 CIDR of the internally used network.
Only applies if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is set to ``true``.


**Type:**::

  IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation


**Default:**::

  "fd00::/120"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/infra.nix

