.. _configuration-options.yk8s.terraform:

yk8s.terraform
^^^^^^^^^^^^^^


Gitlab Terraform backend
""""""""""""""""""""""""

To activate automatic backend of Terraform statefiles to Gitlab,
adapt the Terraform section of your config:
set :ref:`configuration-options.yk8s.terraform.gitlab_backend` to ``true``,
set the URL of the Gitlab project and
the name of the Gitlab state object.

.. code:: nix

  terraform = {
    gitlab_backend    = true;
    gitlab_base_url   = "https://gitlab.com";
    gitlab_project_id = "012345678";
    gitlab_state_name = "tf-state";
  };

Put your Gitlab username and access token
into the ``~/.config/yaook-k8s/env``.
Your Gitlab access token must have
at least Maintainer role and
read/write access to the API.
Please see GitLab documentation for creating a
`personal access token <https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html>`__.

To successful migrate from the "local" to "http" Terraform backend method,
ensure that :ref:`configuration-options.yk8s.terraform.gitlab_backend` is set to ``true``
and all other required variables are set correctly.
Incorrect data entry may result in an HTTP error respond,
such as a HTTP/401 error for incorrect credentials.
Assuming correct credentials in the case of an HTTP/404 error,
Terraform is executed and the state is migrated to Gitlab.

To migrate from the "http" to "local" Terraform backend method,
set :ref:`configuration-options.yk8s.terraform.gitlab_backend` to ``false``,
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

.. _configuration-options.yk8s.terraform.enabled:

``yk8s.terraform.enabled``
##########################



**Type:**::

  boolean


**Default:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.gitlab_backend:

``yk8s.terraform.gitlab_backend``
#################################

Whether to enable GitLab-managed Terraform backend
If true, the Terraform state will be stored inside the provided gitlab project.
If set, the environment `TF_HTTP_USERNAME` and `TF_HTTP_PASSWO = mkOptionD`
must be configured in a separate file `~/.config/yaook-k8s/env`.
.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

  true


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.gitlab_base_url:

``yk8s.terraform.gitlab_base_url``
##################################

The base URL of your GitLab project.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Example:**::

  "https://gitlab.com"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.gitlab_project_id:

``yk8s.terraform.gitlab_project_id``
####################################

The unique ID of your GitLab project.


**Type:**::

  null or non-empty string


**Default:**::

  null


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.gitlab_state_name:

``yk8s.terraform.gitlab_state_name``
####################################

The name of the Gitlab state object in which to store the Terraform state, e.g. 'tf-state'


**Type:**::

  null or non-empty string


**Default:**::

  null


**Example:**::

  "tf-state"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/terraform.nix


.. _configuration-options.yk8s.terraform.timeout_time:

``yk8s.terraform.timeout_time``
###############################



**Type:**::

  non-empty string


**Default:**::

  "30m"


**Declared by**
https://gitlab.com/yaook/k8s/-/tree/devel/nix/yk8s/terraform.nix

