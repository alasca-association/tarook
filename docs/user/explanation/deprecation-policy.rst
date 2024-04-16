Deprecation Policy
==================

Below we outline our policy on deprecating and removing features and kubernetes releases.

For the removal of features and k8s releases from yaook/k8s we will give an advanced
notice of at least 30 days. This notice is given using the
`changelog <https://yaook.gitlab.io/k8s/devel/releasenotes.html>`__.

Support for older releases of yk8s
----------------------------------

A release becomes EOL when there are three newer (major/minor) versions but earliest four weeks
after it has been released. Until then a release will be supported with hotfixes.

Change of vault policies
------------------------

When we need to change vault policies we will first add the new policy and keep both - old and new - in our codebase to allow for transitions from one version to the next.
This is handled as a feature change.
After some time (at least 30 days) we will remove the old policy. This will be a breaking change.

Removal of kubernetes releases
------------------------------

We will always try to support at least two kubernetes versions. We will drop the support for older versions earliest
when they become EOL and announce the removal in advance.
