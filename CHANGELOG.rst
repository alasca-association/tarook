Releasenotes
============

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.0.0/>`__,
and this project will adhere to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`__.

We use `towncrier <https://github.com/twisted/towncrier>`__ for the
generation of our release notes file.

Information about unreleased changes can be found
`here <https://gitlab.com/yaook/k8s/-/tree/devel/docs/_releasenotes?ref_type=heads>`__.

For changes before summer 2023 see the
:ref:`end of this document <changelog.earlier>` and also
``git log --no-merges`` will help you to get a rough overview of
earlier changes.

.. towncrier release notes start

v2.1.0 (2024-02-20)
-------------------

New Features
~~~~~~~~~~~~

- Add support for Kubernetes v1.27 (`!1065 <https://gitlab.com/yaook/k8s/-/merge_requests/1065>`_)
- Allow to enable Ceph dashboard


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Disarm GPU tests until #610 is properly addressed


Bugfixes
~~~~~~~~

- Allow using clusters before and after the introduction of the Root CA
  rotation feature to use the same Vault instance. (`!1069 <https://gitlab.com/yaook/k8s/-/merge_requests/1069>`_)
- Fix loading order in envrc template
- envrc.lib.sh: Run poetry install with --no-root


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Add information on how to pack a release.
- Update information about how to write releasenotes


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Drop support for Kubernetes v1.24 (`!1040 <https://gitlab.com/yaook/k8s/-/merge_requests/1040>`_)


Other Tasks
~~~~~~~~~~~

- Update flake dependencies and allow unfree license for Terraform (`!929 <https://gitlab.com/yaook/k8s/-/merge_requests/929>`_)


Misc
~~~~


v2.0.0 (2024-02-07)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- Add functionality to rotate certificate authorities of a cluster

  This is i.e. needed if the old one is shortly to expire.
  As paths of vault policies have been updated for this feature,
  one **must** update them. Please refer to our documentation about the
  Vault setup. (`!939 <https://gitlab.com/yaook/k8s/-/merge_requests/939>`_)


New Features
~~~~~~~~~~~~

- Add support for generating Kubernetes configuration from Vault

  This allows "logging into Kubernetes" using your Vault credentials. For more
  information, see the updated vault documentation (docs/operation/vault.rst,
  "Using Vault to replace a long-lived admin.conf"). (`!1016 <https://gitlab.com/yaook/k8s/-/merge_requests/1016>`_)


Bugfixes
~~~~~~~~

- Disable automatic certification renewal by kubeadm as we manage certificates via vault
- Fixed variable templates for Prometheus persistent storage configuration


Other Tasks
~~~~~~~~~~~

- Further improvement to the automated release process. (`!1033 <https://gitlab.com/yaook/k8s/-/merge_requests/1033>`_)
- Automatically delete volume snapshots in the CI
- Bump required Python version to >=3.10
- CI: Don't run the containerd job everytime on devel
- Enable renovate bot for Ansible galaxy requirements


v1.0.0 (2024-01-29)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- Add option to configure multiple Wireguard endpoints

  Note that you **must** update the vault policies once. See ``docs/vpn/wireguard.rst`` for further information.

  .. code::

      # execute with root vault token sourced
      bash managed-k8s/tools/vault/init.sh

  - (`!795 <https://gitlab.com/yaook/k8s/-/merge_requests/795>`_)
- Improve smoke tests for dedicated testing nodes

  Smoke tests have been reworked a bit such that they are executing
  on defined testing nodes (if defined) only.
  **You must update your config if you defined testing nodes.** (`!952 <https://gitlab.com/yaook/k8s/-/merge_requests/952>`_)


New Features
~~~~~~~~~~~~

- Add option to migrate terraform backend from local to gitlab (`!622 <https://gitlab.com/yaook/k8s/-/merge_requests/622>`_)
- Add support for Kubernetes v1.26 (`!813 <https://gitlab.com/yaook/k8s/-/merge_requests/813>`_)
- Support the bitnami thanos helm chart

  This will create new service names for thanos in k8s.
  The migration to the bitnami thanos helm chart is triggered by default. (`!816 <https://gitlab.com/yaook/k8s/-/merge_requests/816>`_)
- Add tool to assemble snippets for CephCluster manifest

  Writing the part for the CephCluster manifest describing which disks to be used for Ceph OSDs and metadata devices for every single storage node is error-prone. Once a erroneous manifest has been applied it can be very time-consuming to correct the errors as OSDs have to be un-deployed and wiped before re-applying the correct manifest. (`!855 <https://gitlab.com/yaook/k8s/-/merge_requests/855>`_)
- Add project-specific managers for renovate-bot (`!856 <https://gitlab.com/yaook/k8s/-/merge_requests/856>`_)
- Add option to configure custom DNS nameserver for OpenStack subnet (IPv4) (`!904 <https://gitlab.com/yaook/k8s/-/merge_requests/904>`_)
- Add option to allow snippet annotations for NGINX Ingress controller (`!906 <https://gitlab.com/yaook/k8s/-/merge_requests/906>`_)
- Add configuration option for persistent storage for Prometheus (`!917 <https://gitlab.com/yaook/k8s/-/merge_requests/917>`_)
- Add optional configuration options for soft and hard disk pressure eviction to the ``config.toml``. (`!948 <https://gitlab.com/yaook/k8s/-/merge_requests/948>`_)
- Additionally pull a local copy of the Terraform state for disaster recovery purposes if Gitlab is configured as backend. (`!968 <https://gitlab.com/yaook/k8s/-/merge_requests/968>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Bump default Kubernetes node image to Ubuntu 22.04 (`!756 <https://gitlab.com/yaook/k8s/-/merge_requests/756>`_)
- Update Debian Version for Gateway VMs to 12 (`!824 <https://gitlab.com/yaook/k8s/-/merge_requests/824>`_)
- Spawn Tigera operator on Control Plane only by adjusting its nodeSelector (`!850 <https://gitlab.com/yaook/k8s/-/merge_requests/850>`_)
- A minimum version of v1.5.0 is now required for poetry (`!861 <https://gitlab.com/yaook/k8s/-/merge_requests/861>`_)
- Rework installation procedure of flux

  Flux will be deployed via the community helm chart from now on.
  A migration is automatically triggered (but can be prevented,
  see our flux documentation for further information).
  The old installation method will be dropped very soon. (`!891 <https://gitlab.com/yaook/k8s/-/merge_requests/891>`_)
- Use the v1beta3 kubeadm Configuration format for initialization and join processes (`!911 <https://gitlab.com/yaook/k8s/-/merge_requests/911>`_)
- Switch to new community-owned Kubernetes package repositories

  As the Google-hosted repository got frozen, we're switching over to the community-owned repositories.
  For more information, please refer to https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/#what-are-significant-differences-between-the-google-hosted-and-kubernetes-package-repositories (`!937 <https://gitlab.com/yaook/k8s/-/merge_requests/937>`_)
- Moving IPSec credentials to vault.
  This requires manual migration steps.
  Please check the documentation. (`!949 <https://gitlab.com/yaook/k8s/-/merge_requests/949>`_)
- Don't set resource limits for the NGINX ingress controller by default


Bugfixes
~~~~~~~~

- Create a readable terraform var file (`!817 <https://gitlab.com/yaook/k8s/-/merge_requests/817>`_)
- Fixed the missing gpu flag and monitoring scheduling key (`!819 <https://gitlab.com/yaook/k8s/-/merge_requests/819>`_)
- Update the terraform linter and fix the related issues (`!822 <https://gitlab.com/yaook/k8s/-/merge_requests/822>`_)
- Fixed the check for monitoring common labels in the rook-ceph cluster chart values template. (`!826 <https://gitlab.com/yaook/k8s/-/merge_requests/826>`_)
- Fix the vault.sh script

  The script will stop if a config.hcl file already exists.
  This can be avoided with a prior existence check.
  Coreutils v9.2 changed the behaviour of --no-clobber[1].

  [1] https://github.com/coreutils/coreutils/blob/df4e4fbc7d4605b7e1c69bff33fd6af8727cf1bf/NEWS#L88 (`!828 <https://gitlab.com/yaook/k8s/-/merge_requests/828>`_)
- Added missing dependencies to flake.nix (`!829 <https://gitlab.com/yaook/k8s/-/merge_requests/829>`_)
- ipsec: Include passwordstore role only if enabled

  The ipsec role hasn't been fully migrated to vault yet and still depends on the passwordstore role.
  If ipsec is not used, initializing a password store is not necessary.
  However, as an ansible dependency, it was still run and thus failed if passwordstore hadn't been configured.
  This change adds the role via `include_role` instead of as a dependency. (`!833 <https://gitlab.com/yaook/k8s/-/merge_requests/833>`_)
- Docker support has been removed along with k8s versions <1.24, but some places remained dependent on the now unnecessary variable `container_runtime`. This change removes every use of the variable along with the documentation for migrating from docker to containerd. (`!834 <https://gitlab.com/yaook/k8s/-/merge_requests/834>`_)
- Fix non-gpu clusters

  For non-gpu clusters, the roles containerd and kubeadm-join would fail,
  because the variable has_gpu was not defined. This commit changes the
  order of the condition, so has_gpu is only checked if gpu support is
  enabled for the cluster.

  This is actually kind of a workaround for a bug in Ansible. has_gpu
  would be set in a dependency of both roles, but Ansible skips
  dependencies if they have already been skipped earlier in the play. (`!835 <https://gitlab.com/yaook/k8s/-/merge_requests/835>`_)
- Fix rook for clusters without prometheus

  Previously, the rook cluster chart would always try to create PrometheusRules, which would fail without Prometheus' CRD. This change makes the creation dependent on whether monitoring is enabled or not. (`!836 <https://gitlab.com/yaook/k8s/-/merge_requests/836>`_)
- Fix vault for clusters without prometheus

  Previously, the vault role would always try to create ServiceMonitors, which would fail without Prometheus' CRD. This change makes the creation dependent on whether monitoring is enabled or not. (`!838 <https://gitlab.com/yaook/k8s/-/merge_requests/838>`_)
- Change the default VRRP priorities from 150/100/80 to 150/100/50. This
  makes it less likely that two backup nodes attempt to become primary
  at the same time, avoiding race conditions and flappiness. (`!841 <https://gitlab.com/yaook/k8s/-/merge_requests/841>`_)
- Fix Thanos v1 cleanup tasks during migration to prevent accidental double deletion of resources (`!849 <https://gitlab.com/yaook/k8s/-/merge_requests/849>`_)
- Fixed incorrect templating of Thanos secrets for buckets managed by Terraform and clusters with custom names (`!854 <https://gitlab.com/yaook/k8s/-/merge_requests/854>`_)
- Rename rook_on_openstack field in config.toml to on_openstack (`!888 <https://gitlab.com/yaook/k8s/-/merge_requests/888>`_)
-  (`!889 <https://gitlab.com/yaook/k8s/-/merge_requests/889>`_, `!910 <https://gitlab.com/yaook/k8s/-/merge_requests/910>`_)
- Fixed configuration of host network mode for rook/ceph (`!899 <https://gitlab.com/yaook/k8s/-/merge_requests/899>`_)
- * Only delete volumes, ports and floating IPs from the current OpenStack project on destroy, even if the OpenStack credentials can access more than this project. (`!921 <https://gitlab.com/yaook/k8s/-/merge_requests/921>`_)
- destroy: Ensure port deletion works even if only OS_PROJECT_NAME is set (`!922 <https://gitlab.com/yaook/k8s/-/merge_requests/922>`_)
- destroy: Ensure port deletion works even if both OS_PROJECT_NAME and OS_PROJECT_ID are set (`!924 <https://gitlab.com/yaook/k8s/-/merge_requests/924>`_)
- Add support for ch-k8s-lbaas version 0.7.0. Excerpt from the upstream release notes:

     * Improve scoping of actions within OpenStack. Previously, if the credentials allowed listing of ports or floating IPs outside the current project, those would also be affected. This is generally only the case with OpenStack admin credentials which you aren't supposed to use anyway.

  It is strongly recommended that you upgrade your cluster to use 0.7.0 as soon as possible. To do so, change the version value in the ``ch-k8s-lbaas`` section of your ``config.toml`` to ``"0.7.0"``. (`!938 <https://gitlab.com/yaook/k8s/-/merge_requests/938>`_)
- Fixed collection of Pod logs as job artifacts in the CI. (`!953 <https://gitlab.com/yaook/k8s/-/merge_requests/953>`_)
- Fix forwarding nftable rules for multiple Wireguard endpoints. (`!969 <https://gitlab.com/yaook/k8s/-/merge_requests/969>`_)
- The syntax of the rook cheph ``operator_memory_limit`` and _request was fixed in ``config.toml``. (`!973 <https://gitlab.com/yaook/k8s/-/merge_requests/973>`_)
- Fix migration tasks tasks for Flux (`!976 <https://gitlab.com/yaook/k8s/-/merge_requests/976>`_)
- It is ensured that the values passed to the cloud-config secret are proper strings. (`!980 <https://gitlab.com/yaook/k8s/-/merge_requests/980>`_)
- Fix configuration of Grafana resource limits & requests (`!982 <https://gitlab.com/yaook/k8s/-/merge_requests/982>`_)
- Bump to latest K8s patch releases (`!994 <https://gitlab.com/yaook/k8s/-/merge_requests/994>`_)
- Fix the behaviour of the Terraform backend
  when multiple users are maintaining the same cluster,
  especially when migrating the backend from local to http. (`!998 <https://gitlab.com/yaook/k8s/-/merge_requests/998>`_)
- Constrain kubernetes-validate pip package on Kubernetes nodes (`!1004 <https://gitlab.com/yaook/k8s/-/merge_requests/1004>`_)
- Add automatic migration to community repository for Kubernetes packages
- Create a workaround which should allow the renovate bot to create releasenotes


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Added clarification for available release-note types. (`!830 <https://gitlab.com/yaook/k8s/-/merge_requests/830>`_)
- Add clarification in vault setup. (`!831 <https://gitlab.com/yaook/k8s/-/merge_requests/831>`_)
- Fix tip about .envrc in Environment Variable Reference (`!832 <https://gitlab.com/yaook/k8s/-/merge_requests/832>`_)
- Clarify general upgrade procedure and remove obsolete version specific steps (`!837 <https://gitlab.com/yaook/k8s/-/merge_requests/837>`_)
- The repo link to the prometheus blackbox exporter changed (`!840 <https://gitlab.com/yaook/k8s/-/merge_requests/840>`_)
-  (`!851 <https://gitlab.com/yaook/k8s/-/merge_requests/851>`_, `!853 <https://gitlab.com/yaook/k8s/-/merge_requests/853>`_, `!908 <https://gitlab.com/yaook/k8s/-/merge_requests/908>`_, `!979 <https://gitlab.com/yaook/k8s/-/merge_requests/979>`_)
- Added clarification in initialization for the different ``.envrc`` used. (`!852 <https://gitlab.com/yaook/k8s/-/merge_requests/852>`_)
- Update and convert Terraform documentation to restructured Text (`!904 <https://gitlab.com/yaook/k8s/-/merge_requests/904>`_)
- rook-ceph: Clarify role of mon_volume_storage_class (`!955 <https://gitlab.com/yaook/k8s/-/merge_requests/955>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- remove acng related files (`!978 <https://gitlab.com/yaook/k8s/-/merge_requests/978>`_)


Other Tasks
~~~~~~~~~~~

- We start using our release pipeline. That includes automatic versioning
  and release note generation. (`!825 <https://gitlab.com/yaook/k8s/-/merge_requests/825>`_)
-  (`!839 <https://gitlab.com/yaook/k8s/-/merge_requests/839>`_, `!842 <https://gitlab.com/yaook/k8s/-/merge_requests/842>`_, `!864 <https://gitlab.com/yaook/k8s/-/merge_requests/864>`_, `!865 <https://gitlab.com/yaook/k8s/-/merge_requests/865>`_, `!866 <https://gitlab.com/yaook/k8s/-/merge_requests/866>`_, `!867 <https://gitlab.com/yaook/k8s/-/merge_requests/867>`_, `!868 <https://gitlab.com/yaook/k8s/-/merge_requests/868>`_, `!869 <https://gitlab.com/yaook/k8s/-/merge_requests/869>`_, `!870 <https://gitlab.com/yaook/k8s/-/merge_requests/870>`_, `!871 <https://gitlab.com/yaook/k8s/-/merge_requests/871>`_, `!872 <https://gitlab.com/yaook/k8s/-/merge_requests/872>`_, `!874 <https://gitlab.com/yaook/k8s/-/merge_requests/874>`_, `!875 <https://gitlab.com/yaook/k8s/-/merge_requests/875>`_, `!876 <https://gitlab.com/yaook/k8s/-/merge_requests/876>`_, `!877 <https://gitlab.com/yaook/k8s/-/merge_requests/877>`_, `!878 <https://gitlab.com/yaook/k8s/-/merge_requests/878>`_, `!879 <https://gitlab.com/yaook/k8s/-/merge_requests/879>`_, `!880 <https://gitlab.com/yaook/k8s/-/merge_requests/880>`_, `!881 <https://gitlab.com/yaook/k8s/-/merge_requests/881>`_, `!885 <https://gitlab.com/yaook/k8s/-/merge_requests/885>`_, `!886 <https://gitlab.com/yaook/k8s/-/merge_requests/886>`_, `!890 <https://gitlab.com/yaook/k8s/-/merge_requests/890>`_, `!893 <https://gitlab.com/yaook/k8s/-/merge_requests/893>`_, `!894 <https://gitlab.com/yaook/k8s/-/merge_requests/894>`_, `!895 <https://gitlab.com/yaook/k8s/-/merge_requests/895>`_, `!896 <https://gitlab.com/yaook/k8s/-/merge_requests/896>`_, `!901 <https://gitlab.com/yaook/k8s/-/merge_requests/901>`_, `!907 <https://gitlab.com/yaook/k8s/-/merge_requests/907>`_, `!920 <https://gitlab.com/yaook/k8s/-/merge_requests/920>`_, `!927 <https://gitlab.com/yaook/k8s/-/merge_requests/927>`_)
- Adjusted CI and code base for ansible-lint v6.20 (`!882 <https://gitlab.com/yaook/k8s/-/merge_requests/882>`_)
- Update dependency ansible to v8.5.0 (`!909 <https://gitlab.com/yaook/k8s/-/merge_requests/909>`_)
- Enable renovate for Nix flake (`!914 <https://gitlab.com/yaook/k8s/-/merge_requests/914>`_)
- Unpin poetry in flake.nix (`!915 <https://gitlab.com/yaook/k8s/-/merge_requests/915>`_)
- Update kubeadm api version (`!963 <https://gitlab.com/yaook/k8s/-/merge_requests/963>`_)
- The poetry.lock file will update automatically. (`!965 <https://gitlab.com/yaook/k8s/-/merge_requests/965>`_)
- Changed the job rules for the ci-pipeline. (`!992 <https://gitlab.com/yaook/k8s/-/merge_requests/992>`_)


Security
~~~~~~~~

- Security hardening settings for the nginx ingress controller. (`!972 <https://gitlab.com/yaook/k8s/-/merge_requests/972>`_)


Misc
~~~~

- `!843 <https://gitlab.com/yaook/k8s/-/merge_requests/843>`_, `!847 <https://gitlab.com/yaook/k8s/-/merge_requests/847>`_, `!883 <https://gitlab.com/yaook/k8s/-/merge_requests/883>`_, `!961 <https://gitlab.com/yaook/k8s/-/merge_requests/961>`_, `!966 <https://gitlab.com/yaook/k8s/-/merge_requests/966>`_, `!1007 <https://gitlab.com/yaook/k8s/-/merge_requests/1007>`_


.. _changelog.earlier:

Preversion
----------

Towncrier as tooling for releasenotes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

From now on we use `towncrier <https://github.com/twisted/towncrier>`__
to generate our relasenotes. If you are a developer see the
:ref:`coding guide <coding-guide.towncrier>` for further information.

Add .pre-commit-config.yaml
~~~~~~~~~~~~~~~~~~~~~~~~~~~

This repository now contains pre-commit hooks to validate the linting
stage of our CI (except ansible-lint) before committing. This allows for
a smoother development experience as mistakes can be catched quicker. To
use this, install `pre-commit <https://pre-commit.com>`__ (if you use Nix
flakes, it is automatically installed for you) and then run
``pre-commit install`` to enable the hooks in the repo (if you use
direnv, they are automatically enabled for you).

Create volume snapshot CRDs `(!763) <https://gitlab.com/yaook/k8s/-/merge_requests/763>`__
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can now create snapshots of your openstack PVCs. Missing CRDs and
the snapshot-controller from [1] and [2] where added.

[1]
https://github.com/kubernetes-csi/external-snapshotter/tree/master/client/config/crd

[2]
https://github.com/kubernetes-csi/external-snapshotter/tree/master/deploy/kubernetes/snapshot-controller

Add support for rook v1.8.10
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Update by setting ``version=1.8.10`` and running
``MANAGED_K8S_RELEASE_THE_KRAKEN=true AFLAGS="--diff --tags mk8s-sl/rook" managed-k8s/actions/apply-stage4.sh``

Use poetry to lock dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Poetry allows to declaratively set Python dependencies and lock
versions. This way we can ensure that everybody uses the same isolated
environment with identical versions and thus reduce inconsistencies
between individual development environments.

``requirements.txt`` has been removed. Python dependencies are now
declared in ``pyproject.toml`` and locked in ``poetry.lock``. New deps
can be added using the command ``poetry add package-name``. After
manually editing ``pyproject.toml``, run ``poetry lock`` to update the
lock file.

Drop support for Kubernetes v1.21, v1.22, v1.23
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We’re dropping support for EOL Kubernetes versions.

Add support for Kubernetes v1.25
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We added support for all patch versions of Kubernetes v1.25. One can
either directly create a new cluster with a patch release of that
version or upgrade an existing cluster to one
:doc:`as usual </operation/upgrading-kubernetes>`
via:

.. code:: shell

   # Replace the patch version
   MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.25.10

.. note::

   By default, the Tigera operator is deployed with Kubernetes
   v1.25. Therefore, during the upgrade from Kubernetes v1.24 to v1.25, the
   :ref:`migration to the Tigera operator <calico.migrate-to-operator-based-installation>`
   will be triggered automatically by default!

Add support for Helm-based installation of rook-ceph `(!676) <https://gitlab.com/yaook/k8s/-/merge_requests/676>`__
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Starting with rook v1.7, an official Helm chart is provided and has
become the recommended installation method. The charts take care most
installation and upgrade processes. The role rook_v2 includes adds
support for the Helm-based installation as well as a migration path from
rook_v1.

In order to migrate, make sure that rook v1.7.11 is installed and
healthy, then set use_helm=true in the k8s-service-layer.rook section
and run stage4.

GPU: Rework setup and check procedure `(!750) <https://gitlab.com/yaook/k8s/-/merge_requests/750>`__
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We reworked the setup and smoke test procedure for GPU nodes to be used
inside of Kubernetes [1]. In the last two ShoreLeave-Meetings (our
official development) meetings [2] and our IRC-Channel [3] we asked for
feedback if the old procedure is in use in the wild. As that does not
seem to be the case, we decided to save the overhead of implementing and
testing a migration path. If you have GPU nodes in your cluster and
support for these breaks by the reworked code, please create an issue or
consider rebuilding the nodes with the new procedure.

[1] `GPU Support Documentation <./docs/src/operation/gpu-and-vgpu.md#internal-usage>`__

[2] https://gitlab.com/yaook/meta#subscribe-to-meetings

[3] https://gitlab.com/yaook/meta/-/wikis/home#chat

Change kube-apiserver Service-Account-Issuer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Kube-apiserver now issues service-account tokens with
``https://kubernetes.default.svc`` as issuer instead of
``kubernetes.default.svc``. Tokens with the old issuer are still
considered valid, but should be renewed as this additional support will
be dropped in the future.

This change had to be made to make yaook-k8s pass all
`k8s-conformance tests <https://github.com/cncf/k8s-conformance/blob/master/instructions.md>`__.

Drop support for Kubernetes v1.20
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We’re dropping support for Kubernetes v1.20 as this version is EOL quite
some time. This step has been announced several times in our
`public development meeting <https://gitlab.com/yaook/meta#subscribe-to-meetings>`__.

Drop support for Kubernetes v1.19
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We’re dropping support for Kubernetes v1.19 as this version is EOL quite
some time. This step has been announced several times in our
`public development meeting <https://gitlab.com/yaook/meta#subscribe-to-meetings>`__.

Implement support for Tigera operator-based Calico installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Instead of using a customized manifest-based installation method, we’re
now switching to an
`operator-based installation <https://docs.tigera.io/calico/3.25/about/>`__
method based on the Tigera operator.

**Existing clusters must be migrated.** Please have a look at our
:doc:`Calico documentation </operation/calico>` for further
information.

Support for Kubernetes v1.24
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The LCM now supports Kubernetes v1.24. One can either directly create a
new cluster with a patch release of that version or upgrade an existing
cluster to one as usual via:

.. code:: shell

   # Replace the patch version
   MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.24.10

.. note::

   If you’re using docker as CRI, you **must** migrate to containerd in advance.

Further information are given in the
:doc:`Upgrading Kubernetes documentation </operation/upgrading-kubernetes>`.

Implement automated docker to containerd migration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A migration path to change the container runtime on each node of a
cluster from docker to containerd has been added. More information about
this can be found in the documentation.

Drop support for kube-router
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We’re dropping support for kube-router as CNI. This step has been
announced via our usual communication channels months ago. A migration
path from kube-router to calico has been available quite some time and
is also removed now.

Support for Rook 1.7 added
~~~~~~~~~~~~~~~~~~~~~~~~~~

The LCM now supports Rook v1.7.*. Upgrading is as easy as setting your
rook version to 1.7.11, allowing to release the kraken and running stage
4.

Support for Calico v3.21.6
~~~~~~~~~~~~~~~~~~~~~~~~~~

We now added support for Calico v3.21.6, which is tested against
Kubernetes ``v1.20, v1.21 and v1.22`` by the Calico project team. We
also added the possibility to specify one of our supported Calico
versions (``v3.17.1, v3.19.0, v3.21.6``) through a ``config.toml``
variable: ``calico_custom_version``.

ch-k8s-lbaas now respects NetworkPolicy objects
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you are using NetworkPolicy objects, ch-k8s-lbaas will now interpret
them and enforce restrictions on the frontend. That means that if you
previously only allowlisted the CIDR in which the lbaas agents
themselves reside, your inbound traffic will be dropped now.

You have to add external CIDRs to the network policies as needed to
avoid that.

Clusters where NetworkPolicy objects are not in use or where filtering
only happens on namespace/pod targets are not affected (as LBaaS
wouldn’t have worked there anyway, as it needs to be allowlisted in a
CIDR already).

Add Priority Class to esssential cluster components `(!633) <https://gitlab.com/yaook/k8s/-/merge_requests/633>`__
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The `priority
classes <https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/>`__
``system-cluster-critical`` and ``system-node-critical`` have been added
to all managed and therefore essential services and components. There is
no switch to avoid that. For existing clusters, all managed components
will therefore be restarted/updated once during the next application of
the LCM. This is considered not disruptive.

Decoupling thanos and terraform
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When enabling thanos, one can now prevent terraform from creating a
bucket in the same OpenStack project by setting
``manage_thanos_bucket=false`` in the
``[k8s-service-layer.prometheus]``. Then it’s up to the user to manage
the bucket by configuring an alternative storage backend.

OpenStack: Ensure that credentials are used
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

https://gitlab.com/yaook/k8s/-/merge_requests/625 introduces the role
``check-openstack-credentials`` which fires a token request against the
given Keystone endpoint to ensure that credentials are available. For
details, check the commit messages. This sanity check can be skipped by
either passing ``-e check_openstack_credentials=False`` to your call to
``ansible-playbook`` or by setting
``check_openstack_credentials = True`` in the ``[miscellaneous]``
section of your ``config.toml``.

Thanos: Allow alternative object storage backends
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By providing ``thanos_objectstorage_config_file`` one can tell
``thanos-{compact,store}`` to use a specific (pre-configured) object
storage backend (instead of using the bucket the LCM built for you).
Please note that the usage of thanos still requires that the OpenStack
installation provides a SWIFT backend.
`That’s a bug. <https://gitlab.com/yaook/k8s/-/issues/356>`__

Observation of etcd
~~~~~~~~~~~~~~~~~~~

Our monitoring stack now includes the observation of etcd. To fetch the
metrics securely (cert-auth based), a thin socat-based proxy is
installed inside the kube-system namespace.

Support for Kubernetes v1.23
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The LCM now supports Kubernetes v1.23. One can either directly create a
new cluster with that version or upgrade an existing one as usual via:

.. code:: shell

   # Replace the patch version
   MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.23.11

Further information are given in the
:doc:`Upgrading Kubernetes documentation </operation/upgrading-kubernetes>`.

config.toml: Introduce the mandatory option ``[miscellaneous]/container_runtime``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This must be set to ``"docker"`` for pre-existing clusters. New clusters
should be set up with ``"containerd"``. Migration of pre-existing
clusters from docker to containerd is not yet supported.

Replace ``count`` with ``for_each`` in terraform `(!524) <https://gitlab.com/yaook/k8s/-/merge_requests/524>`__
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform now uses ``for_each`` to manage instances which allows the
user to delete instances of any index without extraordinary terraform
black-magic. The LCM auto-magically orchestrates the migration.

Add action for system updates of initialized nodes `(!429) <https://gitlab.com/yaook/k8s/-/merge_requests/429>`__
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The node system updates have been pulled out into a
:ref:`separate action script <actions-references.system_update_nodessh>`.
The reason for that is, that even though one has not set
``MANAGED_K8S_RELEASE_THE_KRAKEN``, the cache of the package manager of
the host node is updated in stage2 and stage3. That takes quite some
time and is unnecessary as the update itself won’t happen. More
rationales are explained in the commit message of
`e4c62211 <https://gitlab.com/yaook/k8s/-/commit/e4c622114949a7f5108e8b4fa3d4217dcb1345bc>`__.

cluster-repo: Move submodules into dedicated directory `(!433) <https://gitlab.com/yaook/k8s/-/merge_requests/433>`__
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We’re now moving (git) submodules into a dedicated directory
``submodules/``. For users enabling these, the cluster repository starts
to get messy, latest after introducing the option to use
:ref:`customization playbooks <abstraction-layers.customization>`.

As this is a breaking change, users which use at least one submodule
**must** re-execute the
``init.sh``- :ref:`script <actions-references.initsh>`!
The ``init.sh``-script will move your enabled submodules into the
``submodules/`` directory. Otherwise at least the symlink to the
``ch-role-users``- `role <https://gitlab.com/yaook/k8s/-/blob/devel/k8s-base/roles/ch-role-users>`__ will be
broken.

 .. note::

   By re-executing the ``init.sh``, the latest ``devel``
   branch of the ``managed-k8s``-module will be checked out under normal
   circumstances!
