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

Versioning specification
************************

We define the following versioning scheme following the SemVer concept (https://semver.org/) $Major.$Minor.$Patch:

* We increment Major by 1 if we have an incompatible change. This number is defined to be 0 during our current development.
* We increment Minor by 1 every time we added at least one new feature in the release.
* We increment Patch by 1 for every release not introducing a new feature. It starts from 0 for each normal release.

Hotfix process [to be defined]
******************************

.. todo::

    - define hotfix process (related to branching model)

We might from time to time need to build hotfixes for Yaook/k8s. To do this we follow the following process:

.. 1. Create a branch of the merge-base of ``stable`` and ``devel`` into ``hotfix/base/$name`` and create the fix.
.. 2. Create a branch of ``devel`` named ``hotfix/devel/$name`` and merge ``hotfix/base/$name`` into there. Create and merge a MR to ``devel``.
.. 3. Create a branch of ``rolling`` named ``hotfix/rolling/$name`` and cherry pick ``hotfix/base/$name`` into there. Create and merge a MR to ``rolling``. We will bump ``W`` automatically.
.. 4. Create a branch of ``stable`` named ``hotfix/stable/$name`` and  cherry pick ``hotfix/base/$name`` into there. Create and merge a MR to ``stable``. We will bump ``Z`` automatically.
.. 5. For each old release needing this: Create a branch of ``stable-<oldversion>`` named ``hotfix/stable-<oldversion>/$name`` and  cherry pick ``hotfix/base/$name`` into there. Create and merge a MR to ``stable``. We will bump ``Z`` automatically.

Each commit must contain a reference to the original issue using ``Hotfix-For: #$issueid`` to help with transparency.

This process ensures that each hotfix has run through the normal validation pipeline and we can consider it stable.

.. note:: If a hotfix is only relevant for an old version, then create a MR against the corresponding ``release/v$Major.$Minor``-branch directly and skip the other steps.


Graphical example
*****************

.. figure:: /img/release.svg
   :scale: 100%
   :alt: branching-model
   :align: center

.. todo::

    - add hotfixing

Practical implementation
------------------------

The following describes the practical implementation of these concepts.

.. _release-and-versioning-policy.yaook-k8s-implementation:

Yaook/k8s implementation
************************

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

- run all tests (linting, spawn cluster, cluster upgrades, diagnostics)
- tag the commit with ``v$Major.$Minor.$Patch-rc-<build-nr>`` if it's a major or minor release
- create a delayed job (one week) which
    - merges to (or creates the new branch) ``release/v$Major.$Minor``
    - triggers a MR back to ``devel``

The pipeline for ``release/v$Major.$Minor``-branches does again some basic testing (lint, spawn cluster, diagnostics),
generates and publishes the documentation and tags the release with ``v$Major.$Minor.$Patch``.
