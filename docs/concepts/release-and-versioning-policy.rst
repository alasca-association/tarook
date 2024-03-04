Releases and Versioning
=======================

In order to ensure that we do not ship broken things we need to test all changes before releasing them.

Requirements
------------

* Guarantee stability by testing the entire system before releasing it
* Support new Kubernetes versions quickly after their release
* Release new features and fixes in a regular and fast way
* Be able to hotfix old stable releases (this does not mean that we support every old release forever)
* Be able to fix critical bugs/security issues within a few hours while not sacrificing stability

Versioning Overview
-------------------

Yaook/k8s is developed and versioned according to cycles. Each development cycle has a predefined
amount of to-be-implemented features (but can of course have additional features and fixes implemented).
During each cycle contributors can merge changes to the main branch (``devel``) of the k8s repository.

When the cycle ends all changes on the main branch are pushed to a ``release-prepare/v$Major.$Minor.$Patch`` branch.
The goal of the ``release-prepare/v$Major.$Minor.$Patch`` branch is to have a chance to test changes in a stable and controlled way.
Ideally no changes are made to the ``release-prepare/v$Major.$Minor.$Patch`` branch anymore. Only necessary hotfixes are allowed.

The ``release-prepare/v$Major.$Minor.$Patch`` branch is kept like that for a week at which point it merges to (or creates) a (new)
release-branch ``release/v$Major.$Minor`` and gets a final version number.


Detailed branching model
************************

The repository is structured in four branch-types:

``devel``
    The main working branch of the repository. Any change is first merged in here.
    Code in here can be expected to pass all linting as well as very basic functionality tests.
    When developing on Yaook/k8s this should be your base branch. You should not run any useful deployment from here.
    This branch is the only long-living branch.

``feature``
    All changes are developed in feature or fix-branches (the name is free), branching off and merging
    back to devel and therefore passing the beforementioned tests.

``release-prepare/v$Major.$Minor.$Patch``
    For every major and minor release we have a release-branch.
    This version should already be stable enough that it is usable for non-prod use cases.

``release/v$Major.$Minor``
    For every major and minor release we have a separate branch. The ``release-prepare/v$Major.$Minor``-branch is merged into
    or generates a new branch.


.. figure:: /img/release.svg
   :scale: 100%
   :alt: branching-model
   :align: center

Versioning specification
************************

We define the following versioning scheme following the SemVer concept (https://semver.org/) $Major.$Minor.$Patch:

* We increment Major by 1 if we have an incompatible change.
* We increment Minor by 1 every time we added at least one new feature in the release. It starts from 0 for each major release.
* We increment Patch by 1 for every release not introducing a new feature. It starts from 0 for each normal release.


.. _release-and-versioning-policy.yaook-k8s-implementation:

Yaook/k8s implementation
************************

The following describes the practical implementation of these concepts.

The release pipeline of the Yaook/k8s repository is following these steps:
    - create a ``release-prepare/v$Major.$Minor.$Patch``-branch based off
        - ``devel``, if it's a major or minor release
        - the corresponding ``release/v$Major.$Minor``-branch, if it's a patch-release
            - merge ``devel`` into it
    - on the branch do the following:
        - calculate the next version number based on the provided releasenote-files since the last release
          and write it to the version-file
        - generate the changelog using towncrier and remove the old releasenote-files

The pipeline for the ``release-prepare/v$Major.$Minor.$Patch``-branch does the following:
    - run all tests (linting (depending on changes), cluster-tests, diagnostics)
    - tag the commit with ``v$Major.$Minor.$Patch-rc-<build-nr>`` if it's a major or minor release
    - create a delayed job (one week) which
        - merges to (or creates the new branch) ``release/v$Major.$Minor``
        - triggers a MR back to ``devel``

The pipeline for ``release/v$Major.$Minor``-branches
    - does again some basic linting  (depending on changes),
    - generates and publishes the documentation,
    - tags the release with ``v$Major.$Minor.$Patch`` and
    - creates a `Gitlab Release <https://docs.gitlab.com/ee/user/project/releases/>`__.

.. _releases-and-versioning-policy.hotfix-process:

Hotfix process
**************

Please read the full section before starting a hotfix-process. We will outline the mandatory steps here.

Why we established this process
+++++++++++++++++++++++++++++++

We might from time to time need to build hotfixes for yaook/k8s. In this case we need to make sure each release has

- the correct version number,
- a changelog entry,
- a tag and
- a gitlab-release

Also we have to make sure the version and the changelog of ``devel`` is in sync with the latest release.

We introduced a pipeline which will be triggered, if we have a MR with a ``hotfix/..``-branch as source
which will take care of the version and the changelog. The pipeline for the ``release/v..``-branch will take care
of tagging and gitlab-releases, but older releases may not have those jobs integrated, for manual intervention see
:ref:`here <releases-and-versioning-policy.hotfix-process.manual-intervention-for-older-releases>`.

The procedure
+++++++++++++

.. attention::

    See below for the case there is an open ``release-prepare/v$Major.$Minor.$Patch``-branch around!

The following steps are mandatory for the hotfixing-process, the details are up to you and the special case,
but we also added a detailed guideline in our :ref:`coding guide <coding-guide.hotfixes>`:

1. For every release needing the hotfix, create a branch ``hotfix/v$Major.$Minor/$name`` off of ``release/v$Major.$Minor``
2. Somehow commit the fix to the branch and create a MR against ``release/v$Major.$Minor``.

We will update the version-number in ``version`` accordingly and create the changelog using towncrier.
Please make sure the version number is correct (it's a fix for the corresponding release) before merging.

.. important::

    Place your **releasenote** inside ``docs/_releasenotes/hotfix``.

If you have to update the latest release, make sure you also update ``version`` and the changelog on ``devel`` accordingly
as those should always be in sync with the latest release.
Either by also introducing the fix to ``devel`` via a ``hotfix/devel/$name`` branch or by just commiting the needed updates.

This process ensures that each hotfix has run through the normal validation pipeline and we can consider it stable.

.. _releases-and-versioning-policy.hotfix-process.manual-intervention-for-older-releases:

Manual intervention for older releases
######################################

.. important::

    For releases older than this change (February 2024) you need to do the version and changelog-change manually.
    To do so, do:

        1. Change the line in ``version`` from ``x.y.z`` to ``x.y.z+1``.
        2. Add the change in the changelog directly.

    For older releases it may be the case the ci-pipeline does not everything which is included now.
    Make sure the following is done in the ``release/v$Major.$Minor``-branch (if not, do it manually)

        1. Create a tag.
        2. Create a gitlab-release from the tag.

Special case: There is an open ``release-prepare``-branch around
################################################################

.. warning::

    This process is a proposal and has not been tested yet.

If there is an open ``release-prepare/v$Major.$Minor.$Patch``-branch, this means that we are in the process of
rolling out a new release and haven't finished the process yet.
Please have a look at its pipeline. We will differentiate two cases:

1. The ``merge-to-release-branch`` job hasn't started yet.
    1. Stop the pipeline.
    2. Add the fix as a new commit somehow into the ``release-prepare/v$Major.$Minor.$Patch``-branch and start
       the pipeline for the branch again (this should happen automatically).
    3. For all older versions needing the hotfix proceed like described above.
       (Have in mind that the ``release-prepare/v$Major.$Minor.$Patch``-branch could also be a fix-release
       and merge to the last ``release/v$Major.$Minor``-branch)

.. important::

    Don't create a ``hotfix/devel/$name`` branch merging back to devel as the hotfix will be merged
    via the ``release-prepare/v$Major.$Minor.$Patch``-branch!

.. figure:: /img/hotfix-prepare.svg
   :scale: 100%
   :alt: hotfixing-strategy-for-open-release-prepare-branch
   :align: center

2. The ``merge-to-release-branch`` job has been triggered, but the MR back to devel or the release-branch isn't finished.
    - Please wait for the release to be fully finished. Afterwards follow the process described above.
