.. _configuration-options.yk8s.terraform:

yk8s.terraform
^^^^^^^^^^^^^^



.. _configuration-options.yk8s.terraform.enabled:

``yk8s.terraform.enabled``
##########################

Whether to enable Terraform usage.

**Type:**::

  boolean


**Default:**::

  false


**Example:**::

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


.. _configuration-options.yk8s.terraform.prevent_disruption:

``yk8s.terraform.prevent_disruption``
#####################################

If true, prevent Terraform from performing disruptive action
defaults to true if unset


**Type:**::

  boolean


**Default:**::

  true


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

