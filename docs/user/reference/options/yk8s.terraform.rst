.. _configuration-options.yk8s.terraform:

yk8s.terraform
^^^^^^^^^^^^^^


GitLab Terraform backend
""""""""""""""""""""""""

To activate automatic backend of Terraform statefiles to GitLab,
adapt the Terraform section of your config:
set :ref:`configuration-options.yk8s.terraform.backend.gitlab.enabled` to ``true``,
set the URL of the GitLab project and
the name of the GitLab state object.

.. code:: nix

  terraform.backend.gitlab = {
    enabled    = true;
    base_url   = "https://gitlab.com";
    project_id = "012345678";
    state_name = "tf-state";
  };

Put your GitLab username and access token
into the ``~/.config/yaook-k8s/env``.
Your GitLab access token must have
at least Maintainer role and
read/write access to the API.
Please see GitLab documentation for creating a
`personal access token <https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html>`__.

To successful migrate from the "local" to "http" Terraform backend method,
ensure that :ref:`configuration-options.yk8s.terraform.backend.gitlab.enabled` is set to ``true``
and all other required variables are set correctly.
Incorrect data entry may result in an HTTP error respond,
such as a HTTP/401 error for incorrect credentials.
Assuming correct credentials in the case of an HTTP/404 error,
Terraform is executed and the state is migrated to GitLab.

To migrate from the "http" to "local" Terraform backend method,
set :ref:`configuration-options.yk8s.terraform.backend.gitlab.enabled` to ``false``,
`MANAGED_K8S_NUKE_FROM_ORBIT=true`,
and assume
that all variables above are properly set
and the Terraform state exists on GitLab.
Once the migration is successful,
unset the variables above
to continue using the "local" backend method.

.. code:: bash

  export TF_HTTP_USERNAME="<gitlab-username>"
  export TF_HTTP_PASSWORD="<gitlab-access-token>"

.. _configuration-options.yk8s.terraform.backend.gitlab.base_url:

``yk8s.terraform.backend.gitlab.base_url``
##########################################

The base HTTP(s) URL of your GitLab instance.


**Type:**::

  null or RFC3986 HTTP(S) URL (scheme, authority and path only)


**Default:**::

  null


**Example:**::

  "https://gitlab.com"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.backend.gitlab.enabled:

``yk8s.terraform.backend.gitlab.enabled``
#########################################

Whether to enable GitLab-managed Terraform backend
If true, the Terraform state will be stored inside the provided GitLab project.
If set, the environment `TF_HTTP_USERNAME` and `TF_HTTP_PASSWORD`
must be configured in a separate file `~/.config/yaook-k8s/env`.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.backend.gitlab.project_id:

``yk8s.terraform.backend.gitlab.project_id``
############################################

The unique ID of your GitLab project.


**Type:**::

  null or signed integer or RFC3986 URL path segment (pchar)


**Default:**::

  null


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.backend.gitlab.state_name:

``yk8s.terraform.backend.gitlab.state_name``
############################################

The name of the GitLab state object in which to store the Terraform state, e.g. 'tf-state'


**Type:**::

  null or RFC3986 URL path segment (pchar)


**Default:**::

  null


**Example:**::

  "tf-state"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.enabled:

``yk8s.terraform.enabled``
##########################

Whether to enable Terraform usage.
If :ref:`configuration-options.yk8s.openstack.enabled`
or :ref:`configuration-options.yk8s.proxmox.enabled` is true,
Terraform is automatically used and must not be explicitly enabled.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.modules:

``yk8s.terraform.modules``
##########################



**Type:**::

  list of anything


**Default:**::

  [ ]


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.timeout_time:

``yk8s.terraform.timeout_time``
###############################

Timeout duration for Terraform operations

**Type:**::

  Terraform duration string


**Default:**::

  "30m"


**Declared by**
https://gitlab.com/alasca.cloud/tarook/tarook/-/tree/devel/nix/yk8s/terraform.nix

