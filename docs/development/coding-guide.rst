Coding Guide
============

This document contains a coding guideline specifically written for this
repository. For general information please refer to the
`Yaook Development Process Documentation <https://yaook.gitlab.io/meta/01-development-process.html>`__.

pre-commit-hooks
----------------
This repository contains pre-commit hooks to validate the linting stage of our
CI (except ansible-lint) before committing. To use this, install
`pre-commit <https://pre-commit.com>`__
(if you use Nix flakes, it is automatically installed
for you) and then run ``pre-commit install`` to enable the hooks in the repo (if
you use direnv, they are automatically enabled for you).

Disruption
----------

**disruption**

   A *disruption* is defined as a loss of state or data or
   loss of availability.

**disruptive**

   *Disruptive* code is code which may under certain
   circumstances cause a disruption.

Ansible code MUST be written so that it is non-disruptive by default. It
is only allowed to execute disruptive actions if and only if the
``_allow_disruption`` variable evaluates to ``true``.

Examples
~~~~~~~~

(Non-exhaustive) examples of disruptive actions:

-  Restarting docker (for example via a docker upgrade)
-  Draining a worker or master node
-  Killing a pod
-  Rebooting a worker or master node with an OSD on it

Examples of non-disruptive actions:

-  Rebooting a gateway node if at least one other gateway node is up
-  Updating a (non-customer) Deployment via Kubernetes

Ansible Styleguide
------------------

New-style module syntax
~~~~~~~~~~~~~~~~~~~~~~~

**Correct**

.. code:: yaml

   - name: Upgrade all packages
     dnf:
       name:
       - '*'
       state: latest

**Incorrect**

.. code:: yaml

   - name: Upgrade all packages
     dnf: name=* state=latest

.. admonition:: Rationale

   The first version is easier to scan. It also supports the
   use of Jinja2 templates without having to worry about quotation and
   spaces.

Command module usage
~~~~~~~~~~~~~~~~~~~~

**Correct**

.. code:: yaml

   - name: Get node info
     command:
     args:
       argv:
       - kubectl
       - describe
       - node
       - "{{ inventory_hostname }}"

**Also correct**

.. code:: yaml

   - name: Get node info
     command:
     args:
       argv: ["kubectl", "describe", "node", "{{ inventory_hostname }}"]

**Not correct**

.. code:: yaml

   - name: Get node info
     command: "kubectl describe node {{ inventory_hostname }}"

.. admonition:: Rationale

   Spaces and possibly quotes in the hostname would lead to
   issues.

Shell module usage
~~~~~~~~~~~~~~~~~~

**Correct**

.. code:: yaml

   - name: Load shared public key
     shell: "wg pubkey > {{ wg_local_pub_path | quote }} < {{ wg_local_priv_path | quote }}"

**Not correct**

.. code:: yaml

   - name: Load shared public key
     shell: "cat {{ wg_local_priv_path }} | wg pubkey > {{ wg_local_pub_path | quote }}"

**Partially better**

.. code:: yaml

   - name: Load shared public key
     shell: "set -o pipefail && cat {{ wg_local_priv_path }} | wg pubkey > {{ wg_local_pub_path | quote }}"

.. admonition:: Rationale

   - Using pipes in the shell module can lead to silent
     failures without ``set -o pipefail``
   - Variables should be properly escaped. A ‘;’ or a ‘&&’ in, e.g.,
     the path can lead to funny things.
     Especially critial if the content of the variable can be influenced from
     the outside.
   - `The use of cat here is redundant <http://porkmail.org/era/unix/award.html#cat>`__

Use ``to_json`` in templates when writing YAML or JSON
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Correct:**

.. code:: yaml

   {
      "do_create": {{ some_variable | to_json }}
   }

**Incorrect:**

.. code:: yaml

   {
      "do_create": {{ some_variable }}
   }

**Also incorrect:**

.. code:: yaml

   {
      "do_create": "{{ some_variable }}"
   }

.. admonition:: Rationale

   If ``some_variable`` contains data which can be
   interpreted as different data type in YAML (such as ``no`` or ``true``
   or ``00:01``) or quotes which would break the JSON string, unexpected
   effects or syntax errors can occur. ``to_json`` will properly encode the
   data.

Terraform Styleguide
--------------------

Use jsonencode in templates when writing YAML
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Correct:**

.. code:: yaml

   subnet_id: ${jsonencode(some_subnet_id)}

**Incorrect:**

.. code:: yaml

   subnet_id: ${some_subnet_id}

**Also incorrect:**

.. code:: yaml

   subnet_id: "${some_subnet_id}"

.. admonition:: Rationale

   If ``some_subnet_id`` contains data which can be
   interpreted as different data type in YAML (such as ``no`` or ``true``
   or ``00:01``), unexpected effects can occur. ``jsonencode()`` will wrap
   the ``some_subnet_id`` in quotes and also take care of any necessary
   escaping.

.. _coding-guide.towncrier:

Creation of release notes
-------------------------

.. attention::

   No direct editing of the CHANGELOG-file!

We use `towncrier <https://github.com/twisted/towncrier>`__ for
the management of our release notes. Therefore developers must adhere to some
conventions.

- For every MR you need to place a file called
  ``<ticket-ID>.<type>[.BREAKING][.<whatever-you-want>]`` into ``/docs/_releasenotes``.
  The content of the file is the actual release note.

Currently we use the following types:

.. table::

   ============================= ===================================
   type                          description
   ============================= ===================================
   ``feature`` / added           new feature introduced
   ``changed`` / updated         old functionality changed
   ``fix`` ed / bugfixes         any bugfixes
   ``removal`` and deprecations  soon-to-be-removed and removed features
   ``docs``                      changes in the documentation
   ``security``                  security patches
   ``chore``                     behind the scenes stuff
   ``misc``                      everything not needing a description
                                 (even if there is content it's not written
                                 in the releasenotes-file)
   ============================= ===================================

**Breaking changes**

   have to be indicated using ``BREAKING`` like seen above

**No issue related to the MR**

   use ``+`` as ``<ticket-id>``

**Nothing to add to releasenotes**

   name your file ``+.misc.<random>``, this will not provide an entry in the releasenotes

So the following file-names would be valid examples:

.. code:: none

   123.feature
   123.feature.addedsomethingdifferent
   12.docs.rst
   +.misc
   +something.chore.rst
   99.feature.BREAKING.rst
   100.fix.BREAKING.idestroyedeverything.rst

The content in the file can be formated using rst-syntax. Headlines are not allowed.
For further informations see the
`towncrier docu <https://towncrier.readthedocs.io/en/stable/tutorial.html#creating-news-fragments>`__.

Try to keep it short (see `keepachangelog <https://keepachangelog.com/en/1.1.0/>`__) and provide
further information in the related issue/MR.
