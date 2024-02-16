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

.. _coding-guide.towncrier:

Creation of release notes
-------------------------

The changelog/releasenotes is a place, where a user can see, what has changed.
It's a first reference where to look when e.g. something no longer works.
So the important information which needs to be given here is ``what`` has changed.
Not ``why`` or ``how``. These are informations which can be found in the history.
As a developer try to keep it short (see
`keepachangelog <https://keepachangelog.com/en/1.1.0/>`__) and provide
further information in the related issue/MR.

.. attention::

   No direct editing of the CHANGELOG-file!

We use `towncrier <https://github.com/twisted/towncrier>`__ for
the management of our release notes. Therefore developers must adhere to some
conventions.

For every MR you need to place a file called
``<merge-request-ID>.<type>[.<whatever-you-want>]`` into ``/docs/_releasenotes``.
The content of the file is the actual release note and is in reStructuredText format.

The ``merge-request-ID`` will automatically be added/corrected for you.
So if you don't know the ``merge-request-ID`` in advance, just type anything (except ``+``,
which will not be replaced and mark a note with no link to a MR)
instead of the ID. Please provide the file in your last commit as the pipeline will
``git commit --amend`` and ``git push --force`` the corrected filename back to
your branch. Don't forget to ``git pull --rebase=true`` afterwards, if you make new changes.

.. note::

   When you are working in a fork the file won't be changed, but the pipeline will
   fail. Please edit the file manually.

.. note::

   Sometimes the pipeline fails with ``RuntimeError: No releasenote file added.
   Make sure to provide a file with your MR.`` If you provided a note it's likely
   that you have to rebase to ``origin/devel`` to make the pipeline pass.

**Currently we use the following types:**

.. table::

   ============================= ===================================
   type                          description
   ============================= ===================================
   ``BREAKING``                  anything which requires manual intervention
                                 of users or changes the behavior of end
                                 resources or workload
   ``feature``                   new feature introduced
   ``change``                    old functionality changed/updated
   ``fix``                       any bugfixes
   ``removal``                   soon-to-be-removed and removed features
                                 (note our :doc:`policy on deprecation </concepts/deprecation-policy>`)
   ``docs``                      any changes in the documentation
   ``security``                  security patches
   ``chore``                     updating grunt tasks etc, no production
                                 code change, non-user-facing-changes e.g.

                                 - configuration changes (like .gitignore)
                                 - private methods
                                 - update dependencies
                                 - refactoring

   ``misc``                      everything not needing a description and
                                 not of interest to users
                                 (even if there is content it's not written
                                 in the releasenotes-file)
   ============================= ===================================

.. note::

   For **breaking changes** please provide detailed information on what needs to be done
   as an operator.
   Either in the releasenote itself or linking inside the note to some other source
   (e.g. parts in our docs, ..)

**Nothing to report in the releasenotes**

   leave your file empty, this will just leave a link to the corresponding MR.

**Really nothing to add to releasenotes**

   if you just correct a typo or something which really no user cares,
   name your file ``+.misc.<random>``, this will not provide an entry in the releasenotes
   (and no link to a MR)

So the following file-names would be valid examples:

.. code:: none

   123.feature
   12ads3.feature.addedsomethingdifferent
   12.docs.rst
   +.misc.jkdfskjhsfd2
   something.chore.rst
   99.BREAKING.rst
   100.BREAKING.idestroyedeverything.rst
   käsekuchen.fix.istlecker

The content in the file can be formated using rst-syntax. Headlines are not allowed.
For further informations see the
`towncrier docu <https://towncrier.readthedocs.io/en/stable/tutorial.html#creating-news-fragments>`__.

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

If you are responsible for the creation of releases
---------------------------------------------------

**How to trigger a release:**

1. Go to `rdm <https://gitlab.com/yaook/rdm>`__ and start a pipeline setting ``YAOOK_K8S_CI_RELEASE`` to ``true``.
2. After a few minutes there should be a new ``release-prepare/v$Major.$Minor.$Patch``-branch.
3. The pipeline is triggered like described in :ref:`the policy <release-and-versioning-policy.yaook-k8s-implementation>`
4. Make sure the pipeline did pass sucessfully and especially the changelog is rendered correctly, otherwise correct it directly on
   the branch, this will start a new pipeline.
5. If you for whatever reason don't need the predefined timeperiod before the release candidate will become a release,
   manually start the delayed ``merge-to-release-branch``-job.

**What not to do**

- Don't change anything on the ``release-prepare/v$Major.$Minor.$Patch`` branch, after it was merged to the corresponding
   ``release/v$Major.$Minor``-branch. If you see an error or something which needs to be fixed,
   do it before the ``merge-to-release-branch``-job has started or on ``devel`` for the next release.
