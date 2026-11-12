Deprecation Policy
==================

This page describes how Tarook deprecates and removes features,
Vault policies and Kubernetes releases,
and how long Tarook releases are supported.

Announcements
-------------

Every deprecation and removal is announced in the
:doc:`release notes </releasenotes>`.

Deprecated Features
-------------------

A deprecated feature keeps working, but will be removed in a future release.
Avoid it in new deployments and plan to migrate away from it.

A deprecated feature is removed at the earliest in the next major release
following the release that announces the deprecation.

Vault Policies
--------------

When a HashiCorp Vault policy has to change,
the change is made in two steps,
so that clusters can move from one Tarook version to the next:

#. The new policy is added alongside the old one.
   This is a feature change.
#. After at least 30 days, the old policy is removed.
   This is a breaking change.

See :doc:`/developer/explanation/release-and-versioning-policy`
for how feature and breaking changes affect version numbers.

Kubernetes Releases
-------------------

Tarook aims to support all Kubernetes versions that are maintained upstream.
Support for a Kubernetes version is dropped no earlier than its upstream
`end of life <https://kubernetes.io/releases/>`__.

Tarook Releases
---------------

Supported Tarook releases receive hotfixes.
A release reaches end of life (EOL) once three newer major or minor releases
have been published, but no earlier than four weeks after its own release.

For example, if v16.0, v16.1 and v17.0 are released after v15.0,
v15.0 reaches end of life with the release of v17.0,
provided v15.0 is at least four weeks old by then.

The currently supported releases are listed on the
`Releases <https://meta.docs.tarook.cloud/supported_releases.html>`__ page.
