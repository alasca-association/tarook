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

v8.1.4 (2024-10-23)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed which caused Kubernetes updates to fail during PKI renewal if ``kubernetes.controller_manager.enable_signing_requests`` is enabled. (`!1535 <https://gitlab.com/yaook/k8s/-/merge_requests/1535>`_)


v8.1.3 (2024-10-16)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed which prevented Kubernetes workers from joining the cluster. (`!1524 <https://gitlab.com/yaook/k8s/-/merge_requests/1524>`_)


v8.1.2 (2024-10-16)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed which caused frontend nodes which were setup before release v8.1 to potentially do a system update and reboot. (`!1521 <https://gitlab.com/yaook/k8s/-/merge_requests/1521>`_)
- A bug has been fixed which prevented freshly initialized nodes from getting a system update. (`!1521 <https://gitlab.com/yaook/k8s/-/merge_requests/1521>`_)
- The bug which affected existing clusters setup before release v8.1 and caused Kubernetes workers to try to re-join the cluster has been fixed for real now. (`!1521 <https://gitlab.com/yaook/k8s/-/merge_requests/1521>`_)


v8.1.1 (2024-10-07)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed which affected existing clusters setup before release v8.1 and caused Kubernetes workers to try to re-join the cluster. (`!1510 <https://gitlab.com/yaook/k8s/-/merge_requests/1510>`_)


v8.1.0 (2024-10-01)
-------------------

New Features
~~~~~~~~~~~~

- We now have a binary cache for Nix build artifacts, so users won't have to build anything from source. To use it, configure

  .. code:: ini

     extra-substituters = https://yaook.cachix.org
     extra-trusted-public-keys = yaook.cachix.org-1:m85JtxgDjaNa7hcNUB6Vc/BTxpK5qRCqF4yHoAniwjQ=

  in ``/etc/nix/nix.conf`` (`!930 <https://gitlab.com/yaook/k8s/-/merge_requests/930>`_)
- Poetry dependencies are now packaged within the Nix devShell (`!930 <https://gitlab.com/yaook/k8s/-/merge_requests/930>`_)
- Add option to let calico announce the service cluster IP range to
  external peers. This is necessary in setups where external entities
  want to send traffic to cluster IPs instead of pods or node ports. (`!1455 <https://gitlab.com/yaook/k8s/-/merge_requests/1455>`_)
- The devShell can now be selected with the env var ``YAOOK_K8S_DEVSHELL`` (defaulting to ``'default'``) (`!1457 <https://gitlab.com/yaook/k8s/-/merge_requests/1457>`_)
- Support for a separate inventory for the custom stage was added.
  It is used in addition to the main inventory.

  Previously, the custom stage inventory was silently dropped with release v4.0.0.
  This is now noted in the v4.0.0 release notes. (`!1472 <https://gitlab.com/yaook/k8s/-/merge_requests/1472>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Some internal rework has been done to improve runtime performance. (`!1450 <https://gitlab.com/yaook/k8s/-/merge_requests/1450>`_)
- Wireguard client templates now set ``PersistentKeepalive`` to 25 seconds. Existing configurations do not have to be exchanged. (`!1452 <https://gitlab.com/yaook/k8s/-/merge_requests/1452>`_)
- Supported Kubernetes versions have been bumped. (`!1476 <https://gitlab.com/yaook/k8s/-/merge_requests/1476>`_)


Bugfixes
~~~~~~~~

- A missing call to install_prerequisites has been added to upgrade.sh (`!1481 <https://gitlab.com/yaook/k8s/-/merge_requests/1481>`_)
- Spawning clusters on Openstack with apply-all.sh has been fixed (`!1488 <https://gitlab.com/yaook/k8s/-/merge_requests/1488>`_)
- Cluster-health-verification in combination with poetry2nix has been fixed (`!1495 <https://gitlab.com/yaook/k8s/-/merge_requests/1495>`_)
- Devshell reloading in combination with poetry2nix has been fixed (`!1495 <https://gitlab.com/yaook/k8s/-/merge_requests/1495>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- `!1454 <https://gitlab.com/yaook/k8s/-/merge_requests/1454>`_
- A hint to set ``USE_VAULT_IN_DOCKER`` for development setups has been added to :doc:`Initialization documentation </user/guide/initialization>` (`!1461 <https://gitlab.com/yaook/k8s/-/merge_requests/1461>`_)
- The documentation has been updated to ensure compliance with the Kubernetes trademarks and
  streamline to consistently use "YAOOK/K8s for the LCM. (`!1465 <https://gitlab.com/yaook/k8s/-/merge_requests/1465>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- ``tools/patch_config.py`` was removed
  completing its deprecation cycle
  since release 6.1.0. (`!1468 <https://gitlab.com/yaook/k8s/-/merge_requests/1468>`_)


Other Tasks
~~~~~~~~~~~

- `!1459 <https://gitlab.com/yaook/k8s/-/merge_requests/1459>`_, `!1462 <https://gitlab.com/yaook/k8s/-/merge_requests/1462>`_, `!1467 <https://gitlab.com/yaook/k8s/-/merge_requests/1467>`_, `!1473 <https://gitlab.com/yaook/k8s/-/merge_requests/1473>`_, `!1474 <https://gitlab.com/yaook/k8s/-/merge_requests/1474>`_, `!1475 <https://gitlab.com/yaook/k8s/-/merge_requests/1475>`_, `!1477 <https://gitlab.com/yaook/k8s/-/merge_requests/1477>`_, `!1478 <https://gitlab.com/yaook/k8s/-/merge_requests/1478>`_, `!1479 <https://gitlab.com/yaook/k8s/-/merge_requests/1479>`_, `!1480 <https://gitlab.com/yaook/k8s/-/merge_requests/1480>`_, `!1485 <https://gitlab.com/yaook/k8s/-/merge_requests/1485>`_, `!1486 <https://gitlab.com/yaook/k8s/-/merge_requests/1486>`_, `!1487 <https://gitlab.com/yaook/k8s/-/merge_requests/1487>`_, `!1494 <https://gitlab.com/yaook/k8s/-/merge_requests/1494>`_, `!1499 <https://gitlab.com/yaook/k8s/-/merge_requests/1499>`_


Misc
~~~~

- `!1458 <https://gitlab.com/yaook/k8s/-/merge_requests/1458>`_, `!1460 <https://gitlab.com/yaook/k8s/-/merge_requests/1460>`_


v8.0.2 (2024-09-20)
-------------------

Bugfixes
~~~~~~~~

- Spawning clusters on Openstack with apply-all.sh has been fixed (`!1488 <https://gitlab.com/yaook/k8s/-/merge_requests/1488>`_)


v8.0.1 (2024-09-09)
-------------------

Bugfixes
~~~~~~~~

- The release migration script was fixed
  to support bare metal cluster repos as well. (`!1470 <https://gitlab.com/yaook/k8s/-/merge_requests/1470>`_)


v8.0.0 (2024-08-28)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- The YAOOK/K8s Terraform module now allows worker nodes
  to be joined into individual anti affinity groups.

  .. attention:: Action required

     You must migrate your Terraform state
     by running the migration script.

     .. code:: shell

        ./managed-k8s/actions/migrate-to-release.sh

  _ (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)
- The YAOOK/K8s Terraform module
  does not build a default set of nodes (3 masters + 4 workers) anymore
  when no nodes are given. (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)
- The automatic just-in-time migration of Terraform resources
  from ``count`` to ``for_each`` introduced in July 2022
  was removed in favor of a once-and-for-all migration.

  .. code::

      ./managed-k8s/actions/migrate-to-release.sh

  _ (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)
- YAOOK/K8s Terraform does not implicitly assign
  nodes to availability zones anymore
  if actually none was configured for a node.

  For all master and worker nodes,
  availability zones must now be configured explicitly;
  and ``[terraform].enable_az_management`` has been removed therefore.

  Not configuring availability zones,
  now leaves the choice to the cloud controller
  which may or may not select one.
  To achieve the same effect for gateway nodes,
  turn off ``[terraform].spread_gateways_across_azs``.

  .. attention:: Action required

     To prevent Terraform from unneccessarily rebuilding master and worker nodes,
     you must run the migration script.
     This will determine each nodes' availability zone in the Terraform state
     to set in the config for you.

     .. code::

         ./managed-k8s/actions/migrate-to-release.sh

  _ (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)
- The format of the ``[terraform]`` config section changed significantly.

  Terraform nodes are now to be configured as blocks of values
  rather than across separate lists for each type of value.

  Furthermore you now have control over the whole name of Terraform nodes,
  see :ref:`the documentation <cluster-configuration.configuring-terraform>`
  for further details.

  .. code:: diff

       [terraform]

     - masters = 2
     - master_names = ["X", "Y"]
     - master_flavors = ["M", "M"]
     - master_images = ["Ubuntu 20.04 LTS x64", "Ubuntu 22.04 LTS x64"]
     - master_azs = ["AZ1", "AZ3"]
     + #....
     +
     + [terraform.nodes.master-X]
     + role     = "master"  # mandatory
     + flavor   = "M"
     + image    = "Ubuntu 20.04 LTS x64"
     + az       = "AZ1"
     + #....
     +
     + [terraform.nodes.worker-A]
     + role     = "worker"  # mandatory
     + flavor   = "S"
     + image    = "Debian 12 (bookworm)"
     + az       = "AZ3"
       #....

  The gateway/master/worker defaults are consolidated into blocks as well.

  .. code:: diff

       [terraform]

     - gateway_image_name = "Debian 12 (bookworm)"
     - gateway_flavor = "XS"
     - default_master_image_name = "Ubuntu 22.04 LTS x64"
     - default_master_flavor = "M"
     - default_master_root_disk_size = 50
     - default_worker_image_name = "Ubuntu 22.04 LTS x64"
     - default_worker_flavor = "L"
     - default_worker_root_disk_size = 100
     + #....
     +
     + [terraform.gateway_defaults]
     + image                      = "Debian 12 (bookworm)"
     + flavor                     = "XS"
     +
     + [terraform.master_defaults]
     + image                      = "Ubuntu 22.04 LTS x64"
     + flavor                     = "M"
     + root_disk_size             = 50
     +
     + [terraform.worker_defaults]
     + image                      = "Ubuntu 22.04 LTS x64"
     + flavor                     = "L"
     + root_disk_size             = 100
       #....

  The worker anti affinity settings
  ``[terraform].worker_anti_affinity_group_name``
  and ``[terraform].worker_join_anti_affinity_group``
  are merged into ``[terraform.workers.<name>].anti_affinity_group``
  or ``[terraform.worker_defaults].anti_affinity_group``.
  Unset means "no join".

  .. code:: diff

       [terraform]

     - worker_anti_affinity_group_name = "some-affinity-group"
     - worker_join_anti_affinity_group = [false, true]
     + #....
     +
     + [terraform.worker_defaults]
     +
     + [terraform.workers.0]
     +
     + [terraform.workers.1]
     + anti_affinity_group        = "some-affinity-group"

       #....

  .. attention:: Action required

     You must convert your config into the new format.

     .. code:: shell

        ./managed-k8s/actions/migrate-to-release.sh

  _ (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)
- Gateway node names are now index rather than availability zone based,
  leading to names like ``managed-k8s-gw-0`` instead of ``managed-k8s-gw-az1``.

  .. attention:: Action required

     To prevent Terraform from unnecessarily rebuilding gateway nodes,
     you must run the migration script.

     .. code:: shell

        ./managed-k8s/actions/migrate-to-release.sh

  _ (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)


New Features
~~~~~~~~~~~~

- Terraform: Anti affinity group settings are now configurable per worker node. (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)
- Terraform: The amount of gateway nodes created is not dependent
  on the amount of availability zones anymore
  and can be set with ``[terraform].gateway_count``.
  The setting's default yields the previous behavior
  when ``[terraform].spread_gateway_across_azs`` is enabled
  which it is by default. (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)
- A rework has been done which now allows to trigger a specific playbook of k8s-core or k8s-supplements.
  The default behavior of triggering ``install-all.yaml`` has been preserved.
  See :ref:`apply-k8s-core.sh <actions-references.apply-k8s-coresh>` and
  :ref:`apply-k8s-supplements.sh <actions-references.apply-k8s-supplementssh>`
  for usage information. (`!1433 <https://gitlab.com/yaook/k8s/-/merge_requests/1433>`_)
- It is now possible to set the root URL for Grafana (`!1447 <https://gitlab.com/yaook/k8s/-/merge_requests/1447>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The minimum Terraform version is increased to 1.3 (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)


Bugfixes
~~~~~~~~

- Importing the Thanos object storage configuration has been reworked to not fail erroneously. (`!1437 <https://gitlab.com/yaook/k8s/-/merge_requests/1437>`_)


Other Tasks
~~~~~~~~~~~

- The Terraform code responsible for generating the instance resources
  was streamlined. (`!1317 <https://gitlab.com/yaook/k8s/-/merge_requests/1317>`_)
- `!1441 <https://gitlab.com/yaook/k8s/-/merge_requests/1441>`_, `!1442 <https://gitlab.com/yaook/k8s/-/merge_requests/1442>`_, `!1444 <https://gitlab.com/yaook/k8s/-/merge_requests/1444>`_, `!1445 <https://gitlab.com/yaook/k8s/-/merge_requests/1445>`_


v7.0.2 (2024-08-26)
-------------------

Bugfixes
~~~~~~~~

- A bug has been fixed which prevented the configuration of an exposed Vault service. (`!1448 <https://gitlab.com/yaook/k8s/-/merge_requests/1448>`_)


v7.0.1 (2024-08-26)
-------------------

Bugfixes
~~~~~~~~

- kube-state-metrics not being able to read namespace labels has been fixed (`!1438 <https://gitlab.com/yaook/k8s/-/merge_requests/1438>`_)


v7.0.0 (2024-08-22)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- The dual stack support has been reworked and fixed.
  The variable ``dualstack_support`` has been split into two variables,
  ``ipv4_enabled`` (defaults to true) and ``ipv6_enabled`` (defaults to false)
  to allow ipv6-only deployments and a more fine-granular configuration.

  The following configuration changes are recommended, but not mandatory:

  .. code:: diff

    [terraform]
    -dualstack_support = false
    +ipv6_enabled = false

  Existing clusters running on OpenStack must execute the Terraform stage once:

  .. code:: console

    $ ./managed-k8s/actions/apply-terraform.sh

  to re-generate the inventory and hosts file for Ansible. (`!1304 <https://gitlab.com/yaook/k8s/-/merge_requests/1304>`_)


New Features
~~~~~~~~~~~~

- Support for ch-k8s-lbaas v0.8.0 and v0.9.0 has been added.
  The ch-k8s-lbaas version is now an optional variable. To ensure
  the latest supported version is used, one can simply unset it.

  .. code:: console

    $ tomlq --in-place --toml-output 'del(."ch-k8s-lbaas".version)' config/config.toml

  . (`!1304 <https://gitlab.com/yaook/k8s/-/merge_requests/1304>`_)
- Introduce support for setting remote write targets (``[[remote_writes]]``) for Prometheus (`!1396 <https://gitlab.com/yaook/k8s/-/merge_requests/1396>`_)
- Add new modules ``http_api`` and ``http_api_insecure`` for Blackbox exporter allowing status codes 200, 300, 401 to be returned for http probes. ``http_api_insecure`` additionally doesn't care for the issuer of a certificate. (`!1420 <https://gitlab.com/yaook/k8s/-/merge_requests/1420>`_)
- The default version for rook/Ceph has been bumped to v1.14.9. (`!1430 <https://gitlab.com/yaook/k8s/-/merge_requests/1430>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The sysctl settings ``fs.inotify.max_user_instances``, ``fs.inotify.max_user_watches`` and ``vm.max_map_count`` are now also adjusted on master nodes. (`!1419 <https://gitlab.com/yaook/k8s/-/merge_requests/1419>`_)
- The vault image used in the CI and for local development has been changed to "hashicorp/vault". (`!1429 <https://gitlab.com/yaook/k8s/-/merge_requests/1429>`_)


Bugfixes
~~~~~~~~

- `!1426 <https://gitlab.com/yaook/k8s/-/merge_requests/1426>`_


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- We now explain our release withdrawal procedure
  in the :doc:`Release and Versioning Policy </developer/explanation/release-and-versioning-policy>` (`!1376 <https://gitlab.com/yaook/k8s/-/merge_requests/1376>`_)
- The documentation now links to the latest version of the Calico docs
  instead of a specific version (where possible). (`!1408 <https://gitlab.com/yaook/k8s/-/merge_requests/1408>`_)
- The :doc:`generated Terraform docs </developer/reference/terraform-docs>` was updated. (`!1434 <https://gitlab.com/yaook/k8s/-/merge_requests/1434>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- The "global monitoring" functionality has been dropped.
  It was a provider-specific feature and has been dropped
  as the LCM should be kept as general as possible. (`!1270 <https://gitlab.com/yaook/k8s/-/merge_requests/1270>`_)


Other Tasks
~~~~~~~~~~~

- `!1400 <https://gitlab.com/yaook/k8s/-/merge_requests/1400>`_, `!1403 <https://gitlab.com/yaook/k8s/-/merge_requests/1403>`_, `!1404 <https://gitlab.com/yaook/k8s/-/merge_requests/1404>`_, `!1406 <https://gitlab.com/yaook/k8s/-/merge_requests/1406>`_, `!1409 <https://gitlab.com/yaook/k8s/-/merge_requests/1409>`_, `!1411 <https://gitlab.com/yaook/k8s/-/merge_requests/1411>`_, `!1421 <https://gitlab.com/yaook/k8s/-/merge_requests/1421>`_, `!1422 <https://gitlab.com/yaook/k8s/-/merge_requests/1422>`_, `!1425 <https://gitlab.com/yaook/k8s/-/merge_requests/1425>`_, `!1427 <https://gitlab.com/yaook/k8s/-/merge_requests/1427>`_, `!1428 <https://gitlab.com/yaook/k8s/-/merge_requests/1428>`_, `!1431 <https://gitlab.com/yaook/k8s/-/merge_requests/1431>`_


Misc
~~~~

- `!1405 <https://gitlab.com/yaook/k8s/-/merge_requests/1405>`_, `!1407 <https://gitlab.com/yaook/k8s/-/merge_requests/1407>`_, `!1435 <https://gitlab.com/yaook/k8s/-/merge_requests/1435>`_


v6.1.2 (2024-08-19)
-------------------

Bugfixes
~~~~~~~~

- In the v6.0.0 release notes,
  we now draw attention to committing
  ``etc/ssh_known_hosts`` in the cluster repository
  so that the re-enabled SSH host key verification
  does not require every user to use TOFU at first.
  (`!1413 <https://gitlab.com/yaook/k8s/-/merge_requests/1413>`_)


v6.1.1 (2024-08-15)
-------------------

Bugfixes
~~~~~~~~

- Fixed a bug in k8s-login.sh which would fail if the etc directory did not exist. (`!1416 <https://gitlab.com/yaook/k8s/-/merge_requests/1416>`_)


v6.1.0 (2024-08-07)
-------------------

New Features
~~~~~~~~~~~~

- Added support for Kubernetes v1.30 (`!1385 <https://gitlab.com/yaook/k8s/-/merge_requests/1385>`_)
- Configuration options have been added to cert-manager and ingress-controller to further streamline general helm chart handling. (`!1387 <https://gitlab.com/yaook/k8s/-/merge_requests/1387>`_)
- Add ``MANAGED_K8S_GIT_BRANCH`` environment variable to allow specifying a branch that should be checked out when running ``init-cluster-repo.sh``. (`!1388 <https://gitlab.com/yaook/k8s/-/merge_requests/1388>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The mapped Calico versions have been bumped due to a bug which can result in high CPU
  utilization on nodes. If no custom Calico version is configured, Calico will get updated
  automatically on the next rollout. It is strongly recommended to do a rollout.

  .. code:: console

    $ AFLAGS="--diff -t calico" bash managed-k8s/actions/apply-k8s-supplements.sh

  . (`!1393 <https://gitlab.com/yaook/k8s/-/merge_requests/1393>`_)


Bugfixes
~~~~~~~~

- `!1397 <https://gitlab.com/yaook/k8s/-/merge_requests/1397>`_


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Support for Kubernetes v1.27 has been removed (`!1362 <https://gitlab.com/yaook/k8s/-/merge_requests/1362>`_)
- The ``tools/patch_config.py`` script was deprecated in favor of ``tomlq``. (`!1379 <https://gitlab.com/yaook/k8s/-/merge_requests/1379>`_)


Other Tasks
~~~~~~~~~~~

- `!1347 <https://gitlab.com/yaook/k8s/-/merge_requests/1347>`_, `!1368 <https://gitlab.com/yaook/k8s/-/merge_requests/1368>`_, `!1370 <https://gitlab.com/yaook/k8s/-/merge_requests/1370>`_, `!1372 <https://gitlab.com/yaook/k8s/-/merge_requests/1372>`_, `!1378 <https://gitlab.com/yaook/k8s/-/merge_requests/1378>`_, `!1380 <https://gitlab.com/yaook/k8s/-/merge_requests/1380>`_, `!1384 <https://gitlab.com/yaook/k8s/-/merge_requests/1384>`_, `!1386 <https://gitlab.com/yaook/k8s/-/merge_requests/1386>`_, `!1392 <https://gitlab.com/yaook/k8s/-/merge_requests/1392>`_, `!1394 <https://gitlab.com/yaook/k8s/-/merge_requests/1394>`_, `!1398 <https://gitlab.com/yaook/k8s/-/merge_requests/1398>`_, `!1399 <https://gitlab.com/yaook/k8s/-/merge_requests/1399>`_
- The link from Gitlab releases to release notes has been fixed. (`!1371 <https://gitlab.com/yaook/k8s/-/merge_requests/1371>`_)
- The apiserver backend was adapted to modern haproxy versions (`!1381 <https://gitlab.com/yaook/k8s/-/merge_requests/1381>`_)


v6.0.3 (2024-07-22)
-------------------

Updated the changelog after a few patch releases in the v5.1 series
were withdrawn and superseded by another patch release.

Because the v6.0 release series already includes
the breaking change that is removed again in the v5.1 release series,
we kept it and just added it to the v6.0.0 release notes.


v6.0.2 (2024-07-20)
-------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Sourcing lib.sh is now side-effect free (`!1340 <https://gitlab.com/yaook/k8s/-/merge_requests/1340>`_)
- The entrypoint for the custom stage has been moved into the LCM. It now includes
  the connect-to-nodes role and then dispatches to the custom playbook. If you had
  included connect-to-nodes in the custom playbook, you may now remove it.

  .. code:: diff

    diff --git a/k8s-custom/main.yaml b/k8s-custom/main.yaml
    -# Node bootstrap is needed in most cases
    -- name: Initial node bootstrap
    -  hosts: frontend:k8s_nodes
    -  gather_facts: false
    -  vars_files:
    -    - k8s-core-vars/ssh-hardening.yaml
    -    - k8s-core-vars/disruption.yaml
    -    - k8s-core-vars/etc.yaml
    -  roles:
    -    - role: bootstrap/detect-user
    -      tag: detect-user
    -    - role: bootstrap/ssh-known-hosts
    -      tags: ssh-known-hosts

  . (`!1352 <https://gitlab.com/yaook/k8s/-/merge_requests/1352>`_)
- The version of bird-exporter for prometheus has been updated to
  1.4.3, haproxy-exporter to 0.15, and keepalived-exporter to 0.7.0. (`!1357 <https://gitlab.com/yaook/k8s/-/merge_requests/1357>`_)


Bugfixes
~~~~~~~~

-  (`!1366 <https://gitlab.com/yaook/k8s/-/merge_requests/1366>`_)
- The required actions in the notes of release v6.0.0
  were incomplete and are fixed now.


Other Tasks
~~~~~~~~~~~

-  (`!1360 <https://gitlab.com/yaook/k8s/-/merge_requests/1360>`_, `!1361 <https://gitlab.com/yaook/k8s/-/merge_requests/1361>`_, `!1364 <https://gitlab.com/yaook/k8s/-/merge_requests/1364>`_, `!1365 <https://gitlab.com/yaook/k8s/-/merge_requests/1365>`_)


v6.0.1 (2024-07-17)
-------------------

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The default version of the kube-prometheus-stack helm chart has
  been updated to 59.1.0, and prometheus-adapter to version 4.10.0. (`!1314 <https://gitlab.com/yaook/k8s/-/merge_requests/1314>`_)


Bugfixes
~~~~~~~~

- When initializing a new Wireguard endpoint, nftables may not get reloaded. This has been fixed. (`!1339 <https://gitlab.com/yaook/k8s/-/merge_requests/1339>`_)
- If the vault instance is not publicly routable, nodes were not able to
  login to it as the vault certificate handling was faulty.
  This has been fixed. (`!1358 <https://gitlab.com/yaook/k8s/-/merge_requests/1358>`_)
- A fix to properly generate short-lived kubeconfigs with intermediate CAs has been supplied. (`!1359 <https://gitlab.com/yaook/k8s/-/merge_requests/1359>`_)


Other Tasks
~~~~~~~~~~~

-  (`!1335 <https://gitlab.com/yaook/k8s/-/merge_requests/1335>`_, `!1338 <https://gitlab.com/yaook/k8s/-/merge_requests/1338>`_, `!1344 <https://gitlab.com/yaook/k8s/-/merge_requests/1344>`_, `!1345 <https://gitlab.com/yaook/k8s/-/merge_requests/1345>`_, `!1346 <https://gitlab.com/yaook/k8s/-/merge_requests/1346>`_, `!1349 <https://gitlab.com/yaook/k8s/-/merge_requests/1349>`_, `!1350 <https://gitlab.com/yaook/k8s/-/merge_requests/1350>`_, `!1354 <https://gitlab.com/yaook/k8s/-/merge_requests/1354>`_, `!1355 <https://gitlab.com/yaook/k8s/-/merge_requests/1355>`_, `!1356 <https://gitlab.com/yaook/k8s/-/merge_requests/1356>`_)


Misc
~~~~

- `!1337 <https://gitlab.com/yaook/k8s/-/merge_requests/1337>`_, `!1343 <https://gitlab.com/yaook/k8s/-/merge_requests/1343>`_


v6.0.0 (2024-07-02)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- We now use short-lived (8d) kubeconfigs

  The kubeconfig at ``etc/admin.conf`` is now only valid for 8 days after creation (was 1 year). Also, it is now discouraged to check it into version control but instead refresh it on each orchestrator as it is needed using ``tools/vault/k8s-login.sh``.

  If your automation relies on the kubeconfig to be checked into VCS or for it to be valid for one year, you probably need to adapt it.

  In order to switch to the short-lived kubeconfig, run

  .. code:: console

      $ git rm etc/admin.conf
      $ sed --in-place '/^etc\/admin\.conf$/d' .gitignore
      $ git commit etc/admin.conf -m "Remove kubeconfig from git"
      $ ./managed-k8s/tools/vault/init.sh
      $ ./managed-k8s/tools/vault/update.sh
      $ ./managed-k8s/actions/k8s-login.sh

  Which will remove the long-term kubeconfig and generate a short-lived one. (`!1178 <https://gitlab.com/yaook/k8s/-/merge_requests/1178>`_)
- We now provide an opt-in regression fix
  that restores Kubernetes' ability to respond to certificate signing requests.

  Using the fix is completely optional,
  see :doc:`/user/guide/kubernetes/restore-certificate-signing-ability`.
  for futher details.

  **Action required**:
  As a prerequisite for making the regression fix functional
  you must update your Vault policies by executing the following:

  .. code:: shell

      # execute with Vault root token sourced
      ./managed-k8s/tools/vault/init.sh

  . (`!1219 <https://gitlab.com/yaook/k8s/-/merge_requests/1219>`_)
- Some :doc:`environment variables </user/reference/environmental-variables>` have been removed.

  ``WG_USAGE`` and ``TF_USAGE`` have been moved from ``.envrc`` to ``config.toml``.
  If they have been set to false, the respective options ``wireguard.enabled`` and
  ``terraform.enabled`` in ``config.toml`` need to be set accordingly.
  If they were not touched (i.e. they are set to true), no action is required.

  ``CUSTOM_STAGE_USAGE`` has been removed. The custom stage is now always run
  if the playbook exists. No manual action required. (`!1263 <https://gitlab.com/yaook/k8s/-/merge_requests/1263>`_)
- SSH host key verification has been re-enabled. Nodes are getting signed SSH certificates.
  For clusters not using a vault running inside docker as backend, automated certificate renewal
  is configured on the nodes.
  The SSH CA is stored inside ``$CLUSTER_REPOSITORY/etc/ssh_known_hosts`` and can be used to ssh to nodes.

  Attention: Make sure that file is not gitignored and is committed after rollout.

  The vault policies have been adjusted to allow the orchestrator role to read the SSH CA from vault.
  You must update the vault policies therefore:

  .. note::

     A root token is required.

  .. code:: console

     $ ./managed-k8s/tools/vault/init.sh

  This is needed just once. (`!1272 <https://gitlab.com/yaook/k8s/-/merge_requests/1272>`_)
- With Kubernetes v1.29, the user specified in the ``admin.conf`` kubeconfig
  is now bound to the ``kubeadm:cluster-admins`` RBAC group.
  This requires an update to the Vault cluster policies and configuration.

  **You must update your vault policies and roles and a root token must be sourced.**

  .. code:: console

      $ ./managed-k8s/tools/vault/init.sh
      $ ./managed-k8s/tools/vault/update.sh

  To upgrade your Kubernetes cluster from version v1.28 to v1.29, follow these steps:

  .. warning::

      You must upgrade to a version greater than ``v1.29.5`` due to
      `kubeadm #3055 <https://github.com/kubernetes/kubeadm/issues/3055>`_

  .. code:: console

      $ MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.29.x
      $ ./managed-k8s/actions/k8s-login.sh

  Note that the default upgrade procedure has changed such that addons get upgraded
  after all control plane nodes got upgraded and not along with the first control plane node. (`!1284 <https://gitlab.com/yaook/k8s/-/merge_requests/1284>`_)
- Use volumeV3 client at terraform. volumeV2 is not supported everywhere.

  .. note::

      This breaking change was originally introduced by release 5.1.2,
      but was reverted again with release 5.1.5
      as release 5.1.2 got withdrawn.

  If you have ``[terraform].create_root_disk_on_volume = true`` set in your config,
  you must migrate the ``openstack_blockstorage_volume_v2`` resources
  in your Terraform state to the v3 resource type
  in order to prevent rebuilds of all servers and their volumes.

  .. code:: shell

      # Execute the lines produced by the following script
      # This will import all v2 volumes as v3 volumes
      #  and remove the v2 volume resources from the Terraform state.

      terraform_module="managed-k8s/terraform"
      terraform_config="../../terraform/config.tfvars.json"
      for item in $( \
          terraform -chdir=$terraform_module show -json \
          | jq --raw-output '.values.root_module.resources[] | select(.type == "openstack_blockstorage_volume_v2") | .name+"[\""+.index+"\"]"+","+.values.id' \
      ); do
          echo "terraform -chdir=$terraform_module import -var-file=$terraform_config 'openstack_blockstorage_volume_v3.${item%,*}' '${item#*,}' " \
               "&& terraform -chdir=$terraform_module state rm 'openstack_blockstorage_volume_v2.${item%,*}'"
      done

  (`!1245 <https://gitlab.com/yaook/k8s/-/merge_requests/1245>`_)


New Features
~~~~~~~~~~~~

- Add option to install CCM and cinder csi plugin via helm charts.
  The migration to the helm chart will be enforced when upgrading to Kubernetes v1.29. (`!1107 <https://gitlab.com/yaook/k8s/-/merge_requests/1107>`_)
- A guide on how to rotate OpenStack credentials has been added. (`!1266 <https://gitlab.com/yaook/k8s/-/merge_requests/1266>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The CI image is now built as part of this repo's pipeline using a Nix Flake (`!1175 <https://gitlab.com/yaook/k8s/-/merge_requests/1175>`_)
- Thanos CPU limits have been removed (`!1186 <https://gitlab.com/yaook/k8s/-/merge_requests/1186>`_)
- PKI renewal during Kubernetes upgrades has been refined and can be explicitly triggered or skipped via the newly introduced ``renew-pki`` tag. (`!1251 <https://gitlab.com/yaook/k8s/-/merge_requests/1251>`_)
- All releasenotes will now have a link to their corresponding MR. (`!1294 <https://gitlab.com/yaook/k8s/-/merge_requests/1294>`_)
-  (`!1325 <https://gitlab.com/yaook/k8s/-/merge_requests/1325>`_)


Bugfixes
~~~~~~~~

- Adjust .gitignore template to keep the whole inventory (`!1274 <https://gitlab.com/yaook/k8s/-/merge_requests/1274>`_)
  **Action recommended**: Adapt your .gitignore with ``sed --in-place '/^!\?\/inventory\/.*$/d' .gitignore``.
- After each phase of a root CA rotation a new kubeconfig is automatically generated (`!1293 <https://gitlab.com/yaook/k8s/-/merge_requests/1293>`_)
-  (`!1298 <https://gitlab.com/yaook/k8s/-/merge_requests/1298>`_, `!1316 <https://gitlab.com/yaook/k8s/-/merge_requests/1316>`_, `!1336 <https://gitlab.com/yaook/k8s/-/merge_requests/1336>`_)
- The common monitoring labels feature has been fixed. (`!1303 <https://gitlab.com/yaook/k8s/-/merge_requests/1303>`_)
- Keys in the wireguard endpoint dict have been fixed. (`!1329 <https://gitlab.com/yaook/k8s/-/merge_requests/1329>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- add hints for terraform config (`!1246 <https://gitlab.com/yaook/k8s/-/merge_requests/1246>`_)
- A variable setting to avoid problems with the keyring backend has been added to the template of ``~/.config/yaook-k8s/env``. (`!1269 <https://gitlab.com/yaook/k8s/-/merge_requests/1269>`_)
- A hint to fix incorrect locale settings for Ansible has been added. (`!1297 <https://gitlab.com/yaook/k8s/-/merge_requests/1297>`_)
-  (`!1308 <https://gitlab.com/yaook/k8s/-/merge_requests/1308>`_, `!1315 <https://gitlab.com/yaook/k8s/-/merge_requests/1315>`_)
- A missing variable has been added to the reference (`!1313 <https://gitlab.com/yaook/k8s/-/merge_requests/1313>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Support for rook_v1 has been dropped. We do only support deploying rook via helm from now on. (`!1042 <https://gitlab.com/yaook/k8s/-/merge_requests/1042>`_)
- Deprecated vault policies have been removed after a sufficient transition time.

  .. hint::

    A root token is required.

  .. code:: console

    ./managed-k8s/tools/vault/init.sh

  Execute the above to remove them from your vault instance. (`!1318 <https://gitlab.com/yaook/k8s/-/merge_requests/1318>`_)


Other Tasks
~~~~~~~~~~~

-  (`!1268 <https://gitlab.com/yaook/k8s/-/merge_requests/1268>`_, `!1276 <https://gitlab.com/yaook/k8s/-/merge_requests/1276>`_, `!1281 <https://gitlab.com/yaook/k8s/-/merge_requests/1281>`_, `!1282 <https://gitlab.com/yaook/k8s/-/merge_requests/1282>`_, `!1287 <https://gitlab.com/yaook/k8s/-/merge_requests/1287>`_, `!1296 <https://gitlab.com/yaook/k8s/-/merge_requests/1296>`_, `!1301 <https://gitlab.com/yaook/k8s/-/merge_requests/1301>`_, `!1306 <https://gitlab.com/yaook/k8s/-/merge_requests/1306>`_, `!1307 <https://gitlab.com/yaook/k8s/-/merge_requests/1307>`_, `!1309 <https://gitlab.com/yaook/k8s/-/merge_requests/1309>`_, `!1310 <https://gitlab.com/yaook/k8s/-/merge_requests/1310>`_, `!1311 <https://gitlab.com/yaook/k8s/-/merge_requests/1311>`_, `!1312 <https://gitlab.com/yaook/k8s/-/merge_requests/1312>`_, `!1319 <https://gitlab.com/yaook/k8s/-/merge_requests/1319>`_, `!1320 <https://gitlab.com/yaook/k8s/-/merge_requests/1320>`_, `!1321 <https://gitlab.com/yaook/k8s/-/merge_requests/1321>`_, `!1322 <https://gitlab.com/yaook/k8s/-/merge_requests/1322>`_, `!1334 <https://gitlab.com/yaook/k8s/-/merge_requests/1334>`_)


Security
~~~~~~~~

- All Ansible tasks that handle secret keys are now prevented from logging them. (`!1295 <https://gitlab.com/yaook/k8s/-/merge_requests/1295>`_)


Misc
~~~~

- `!1271 <https://gitlab.com/yaook/k8s/-/merge_requests/1271>`_, `!1328 <https://gitlab.com/yaook/k8s/-/merge_requests/1328>`_


v5.1.5 (2024-07-22)
-------------------

.. note::

    This release replaces all releases since and including 5.1.2.

Patch release 5.1.2 and its successors 5.1.3 and 5.1.4 were withdrawn due to
`#676 "Release v5.1.2 is breaking due to openstack_blockstorage_volume_v3" <https://gitlab.com/yaook/k8s/-/issues/676>`_

This release reverts the breaking change introduced by
`!1245 "terraform use volume_v3 API" <https://gitlab.com/yaook/k8s/-/merge_requests/1245>`_,
while retaining all other changes introduced by the withdrawn releases that were withdrawn.

`!1245 "terraform use volume_v3 API" <https://gitlab.com/yaook/k8s/-/merge_requests/1245>`_
will be re-added with a later major release.

.. attention::

    DO NOT update to this or a higher non-major release if you are currently
    on one of the withdrawn releases.
    Make sure to only upgrade to the major release *which re-adds*
    `!1245 "terraform use volume_v3 API" <https://gitlab.com/yaook/k8s/-/merge_requests/1245>`_
    instead.

v5.1.4 (2024-06-07) [withdrawn]
-------------------------------

Bugfixes
~~~~~~~~

- The root CA rotation has been fixed. (`!1289 <https://gitlab.com/yaook/k8s/-/merge_requests/1289>`_)


v5.1.3 (2024-06-06) [withdrawn]
-------------------------------

New Features
~~~~~~~~~~~~

- A Poetry group has been added so update-inventory.py can be called with minimal dependencies. (`!1277 <https://gitlab.com/yaook/k8s/-/merge_requests/1277>`_)


v5.1.2 (2024-05-27) [withdrawn]
-------------------------------

.. note::

    This release was withdrawn due to
    `#676 "Release v5.1.2 is breaking due to openstack_blockstorage_volume_v3" <https://gitlab.com/yaook/k8s/-/issues/676>`_

Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The default version of the Thanos Helm Chart has been updated to 15.1.0 (`!1188 <https://gitlab.com/yaook/k8s/-/merge_requests/1188>`_)
- Make hosts file backing up more robust in bare metal clusters. (`!1236 <https://gitlab.com/yaook/k8s/-/merge_requests/1236>`_)
- Use volumeV3 client at terraform. volumeV2 is not supported everywhere. (`!1245 <https://gitlab.com/yaook/k8s/-/merge_requests/1245>`_)


Bugfixes
~~~~~~~~

-  (`!1255 <https://gitlab.com/yaook/k8s/-/merge_requests/1255>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Terraform references updated (`!1189 <https://gitlab.com/yaook/k8s/-/merge_requests/1189>`_)
- A guide on how to simulate a self-managed bare metal cluster on
  top of OpenStack has been added to the :doc:`documentation </developer/guide/simulate-bm>`. (`!1231 <https://gitlab.com/yaook/k8s/-/merge_requests/1231>`_)
- Instructions to install Vault have been added to the installation guide (`!1247 <https://gitlab.com/yaook/k8s/-/merge_requests/1247>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- A service-account-issuer patch for kube-apiserver has been removed which was necessary for a flawless transition to an OIDC conformant HTTPS URL (`!1252 <https://gitlab.com/yaook/k8s/-/merge_requests/1252>`_)
- Support for Kubernetes v1.26 has been removed (`!1253 <https://gitlab.com/yaook/k8s/-/merge_requests/1253>`_)


Misc
~~~~

- `!1230 <https://gitlab.com/yaook/k8s/-/merge_requests/1230>`_, `!1235 <https://gitlab.com/yaook/k8s/-/merge_requests/1235>`_


v5.1.1 (2024-05-21)
-------------------

Bugfixes
~~~~~~~~

- The LCM is again able to retrieve the default subnet CIDR
  when ``[terraform].subnet_cidr`` is not set in the config.toml. (`!1249 <https://gitlab.com/yaook/k8s/-/merge_requests/1249>`_)


v5.1.0 (2024-05-07)
-------------------

New Features
~~~~~~~~~~~~

- An option to use a minimal virtual Python environment has been added.
  Take a look at :doc:`Minimal Access Venv </user/guide/minimal-access-venv>`. (`!1225 <https://gitlab.com/yaook/k8s/-/merge_requests/1225>`_)


Bugfixes
~~~~~~~~

- Dummy build the changelog for the current releasenotes in the ci
  ``build-docs-check``-job (`!1234 <https://gitlab.com/yaook/k8s/-/merge_requests/1234>`_)


v5.0.0 (2024-05-02)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- Added the ``MANAGED_K8S_DISRUPT_THE_HARBOUR`` environment variable.

  Disruption of harbour infrastructure is now excluded from ``MANAGED_K8S_RELEASE_THE_KRAKEN``.
  To allow it nonetheless ``MANAGED_K8S_DISRUPT_THE_HARBOUR`` needs to be set instead.
  (See documentation on environment variables)

  ``[terraform].prevent_disruption`` has been added in the config
  to allow the environment variable to be overridden
  when Terraform is used (``TF_USAGE=true``).
  It is set to ``true`` by default.

  Ultimately this prevents unintended destruction of the harbour infrastructure
  and hence the whole YAOOK/K8s deployment
  when ``MANAGED_K8S_RELEASE_THE_KRAKEN`` must be used,
  e.g. during Kubernetes upgrades. (`!1176 <https://gitlab.com/yaook/k8s/-/merge_requests/1176>`_)
- Vault tools now read the cluster name from ``config.toml``

  If your automation relies on any tool in ``./tools/vault/``, you  need to adapt its signature. ``<clustername>`` has been removed as the first argument. (`!1179 <https://gitlab.com/yaook/k8s/-/merge_requests/1179>`_)


New Features
~~~~~~~~~~~~

- Support for Kubernetes v1.28 has been added (`!1205 <https://gitlab.com/yaook/k8s/-/merge_requests/1205>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Proof whether the WireGuard networks and the cluster network are disjoint (`!1049 <https://gitlab.com/yaook/k8s/-/merge_requests/1049>`_)
- The LCM has been adjusted to talk to the K8s API via the orchestrator node only (`!1202 <https://gitlab.com/yaook/k8s/-/merge_requests/1202>`_)


Bugfixes
~~~~~~~~

- Cluster repository migration has been fixed for bare metal clusters. (`!1183 <https://gitlab.com/yaook/k8s/-/merge_requests/1183>`_)
- Core Split migration script doesn't fail anymore when inventory folder is missing (`!1196 <https://gitlab.com/yaook/k8s/-/merge_requests/1196>`_)
-  (`!1203 <https://gitlab.com/yaook/k8s/-/merge_requests/1203>`_)
- Some images got moved to the yaook registry, so we updated the image path.

  For ``registry.yaook.cloud/yaook/backup-shifter:1.0.166`` a newer tag needs to be
  used, as the old one is not available at new registry. (`!1206 <https://gitlab.com/yaook/k8s/-/merge_requests/1206>`_)
- Cluster repo initialization with ``./actions/init-cluster-repo.sh``
  does not fail anymore when the config already exists. (`!1211 <https://gitlab.com/yaook/k8s/-/merge_requests/1211>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- The documentation has been reworked according to `Diátaxis <https://diataxis.fr/>`__. (`!1181 <https://gitlab.com/yaook/k8s/-/merge_requests/1181>`_)
- Add user tutorial on how to create a cluster (`!1191 <https://gitlab.com/yaook/k8s/-/merge_requests/1191>`_)
- Add copybutton for code (`!1193 <https://gitlab.com/yaook/k8s/-/merge_requests/1193>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Support for the legacy installation procedure of Thanos with jsonnet has been dropped (`!1214 <https://gitlab.com/yaook/k8s/-/merge_requests/1214>`_)


Other Tasks
~~~~~~~~~~~

- Added `yq <https://github.com/mikefarah/yq>`_ as a dependency.
  This allows shell scripts to read the config with ``tomlq``. (`!1176 <https://gitlab.com/yaook/k8s/-/merge_requests/1176>`_)
- Helm module execution is not retried anymore as that obfuscated failed rollouts (`!1215 <https://gitlab.com/yaook/k8s/-/merge_requests/1215>`_)
-  (`!1218 <https://gitlab.com/yaook/k8s/-/merge_requests/1218>`_)


Misc
~~~~

- `!1204 <https://gitlab.com/yaook/k8s/-/merge_requests/1204>`_


v4.0.0 (2024-04-15)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- The first and main serve of the core-split has been merged and the code base has been tossed around.
  One MUST take actions to migrate a pre-core-split cluster.

  .. code::

      $ bash managed-k8s/actions/migrate-cluster-repo.sh

  This BREAKS the air-gapped and cluster-behind-proxy functionality.

  Please refer to the :doc:`respective documentation </user/reference/actions-references>` (`!823 <https://gitlab.com/yaook/k8s/-/merge_requests/823>`_).

- The custom stage now uses the main inventory exclusively,
  like all other stages.
  A seperate inventory for the custom stage is not supported anymore
  and will be removed by the migrate-cluster-repo action.


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- The custom stage is enabled by default now. (`!823 <https://gitlab.com/yaook/k8s/-/merge_requests/823>`_)
- Change etcd-backup to use the new Service and ServiceMonitor manifests supplied by the Helm chart.

  The old manifests that were included in the YAOOK/K8s repo in the past will be overwritten
  (``etcd-backup`` ServiceMonitor) and removed (``etcd-backup-monitoring`` Service) in
  existing installations. (`!1131 <https://gitlab.com/yaook/k8s/-/merge_requests/1131>`_)


Bugfixes
~~~~~~~~

- Fix patch-release tagging (`!1169 <https://gitlab.com/yaook/k8s/-/merge_requests/1169>`_)
- Change of the proposed hotfix procedure (`!1171 <https://gitlab.com/yaook/k8s/-/merge_requests/1171>`_)
-  (`!1172 <https://gitlab.com/yaook/k8s/-/merge_requests/1172>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Streamline Thanos bucket management configuration (`!1173 <https://gitlab.com/yaook/k8s/-/merge_requests/1173>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Dropping the ``on_openstack`` variable from the ``[k8s-service-layer.rook]`` section

  Previously, this was a workaround to tell rook if we're running on top of OpenStack or not.
  With the new repository layout that's not needed anymore as the ``on_openstack`` variable is specified
  in the hosts file (``inventory/yaook-k8s/hosts``) and available when invoking the rook roles. (`!823 <https://gitlab.com/yaook/k8s/-/merge_requests/823>`_)
- Remove configuration option for Thanos query persistence

  As that's not possible to set via the used helm chart and
  the variable is useless. (`!1174 <https://gitlab.com/yaook/k8s/-/merge_requests/1174>`_)


Other Tasks
~~~~~~~~~~~

- Disable "-rc"-tagging (`!1170 <https://gitlab.com/yaook/k8s/-/merge_requests/1170>`_)


v3.0.2 (2024-04-09)
-------------------

Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Add some details about Thanos configuration (`!1146 <https://gitlab.com/yaook/k8s/-/merge_requests/1146>`_)

Misc
~~~~

- `!1144 <https://gitlab.com/yaook/k8s/-/merge_requests/1144>`_, `!1145 <https://gitlab.com/yaook/k8s/-/merge_requests/1145>`_


v3.0.1 (2024-04-03)
-------------------

Bugfixes
~~~~~~~~

- Fix Prometheus stack deployment

  If ``scheduling_key`` and ``allow_external_rules`` where set,
  rendering the values file for the Prometheus-stack failed due to wrong indentation.
  Also the ``scheduling_key`` did not take effect even without
  ``allow_external_rules`` configured due to the wrong indentation. (`!1142 <https://gitlab.com/yaook/k8s/-/merge_requests/1142>`_)


v3.0.0 (2024-03-27)
-------------------

Breaking changes
~~~~~~~~~~~~~~~~

- Drop passwordstore functionality

  We're dropping the already deprecated and legacy passwordstore functionality.
  As the inventory updater checks for valid sections in the "config/config.toml" only,
  the "[passwordstore]" section must be dropped in its entirety for existing clusters. (`!996 <https://gitlab.com/yaook/k8s/-/merge_requests/996>`_)
- Adjust configuration for persistence of Thanos components

  Persistence for Thanos components can be enabled/disabled by setting/unsetting
  ``k8s-service-layer.prometheus.thanos_storage_class``. It is disabled by default.
  You must adjust your configuration to re-enable it. Have a lookt at the configuration template.
  Furthermore, volume size for each component can be configured separately. (`!1106 <https://gitlab.com/yaook/k8s/-/merge_requests/1106>`_)
- Fix disabling storage class creation for rook/ceph pools

  Previously, the ``create_storage_class`` attribute of a ceph pool was a string which has been
  interpreted as boolean. This has been changed and that attribute must be a boolean now.

  .. code:: toml

    [[k8s-service-layer.rook.pools]]
    name = "test-true"
    create_storage_class = true
    replicated = 3

  This is restored behavior pre-rook_v2, where storage classes for ceph blockpools
  didn't get created by default. (`!1130 <https://gitlab.com/yaook/k8s/-/merge_requests/1130>`_)
- The Thanos object storage configuration must be moved to vault
  if it is not automatically managed.
  Please check the documentation on how to create a configuration
  and move it to vault.

  **You must update your vault policies if you use Thanos with a
  custom object storage configuration**

  .. code:: shell

      ./managed-k8s/tools/vault/update.sh $CLUSTER_NAME

  Execute the above to update your vault policies.
  A root token must be sourced.


New Features
~~~~~~~~~~~~

- Add Sonobuoy testing to CI (`!957 <https://gitlab.com/yaook/k8s/-/merge_requests/957>`_)
- Add support to define memory limits for the kube-apiservers

  The values set in the ``config.toml`` are only applied on K8s upgrades.
  If no values are explicitly configured, no memory resource requests nor limits
  will be set by default. (`!1027 <https://gitlab.com/yaook/k8s/-/merge_requests/1027>`_)
- Thanos: Add option to configure in-memory index cache sizes (`!1116 <https://gitlab.com/yaook/k8s/-/merge_requests/1116>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Poetry virtual envs are now deduplicated between cluster repos and can be switched much more quickly (`!931 <https://gitlab.com/yaook/k8s/-/merge_requests/931>`_)
- Allow unsetting CPU limits for rook/ceph components (`!1089 <https://gitlab.com/yaook/k8s/-/merge_requests/1089>`_)
- Add check whether VAULT_TOKEN is set for stages 2 and 3 (`!1108 <https://gitlab.com/yaook/k8s/-/merge_requests/1108>`_)
- Enable auto-downsampling for Thanos query (`!1116 <https://gitlab.com/yaook/k8s/-/merge_requests/1116>`_)
- Add option for testing clusters
  to enforce the reboot of the nodes
  after each system update
  to simulate the cluster behaviour in a real world. (`!1121 <https://gitlab.com/yaook/k8s/-/merge_requests/1121>`_)
- Add a new env var ``$MANAGED_K8S_LATEST_RELEASE`` for the ``init.sh`` script which is true by default and causes that the latest release is checked out instead of ``devel`` (`!1122 <https://gitlab.com/yaook/k8s/-/merge_requests/1122>`_)


Bugfixes
~~~~~~~~

- Fix & generalize scheduling_key usage for managed K8s services (`!1088 <https://gitlab.com/yaook/k8s/-/merge_requests/1088>`_)
- Fix vault import for non-OpenStack clusters (`!1090 <https://gitlab.com/yaook/k8s/-/merge_requests/1090>`_)
- Don't create Flux PodMonitos if monitoring is disabled (`!1092 <https://gitlab.com/yaook/k8s/-/merge_requests/1092>`_)
- Fix a bug which prevented nuking a cluster if Gitlab is used as Terraform backend (`!1093 <https://gitlab.com/yaook/k8s/-/merge_requests/1093>`_)
- Fix tool ``tools/assemble_cephcluster_storage_nodes_yaml.py`` to produce
  valid yaml.

  The tool helps to generate a Helm value file for rook-ceph-cluster Helm
  chart. The data type used for encryptedDevice in yaml path
  cephClusterSpec.storage has been fixed. It was boolean before but need to
  be string. (`!1118 <https://gitlab.com/yaook/k8s/-/merge_requests/1118>`_)
-  (`!1120 <https://gitlab.com/yaook/k8s/-/merge_requests/1120>`_)
- Ensure minimal IPSec package installation (`!1129 <https://gitlab.com/yaook/k8s/-/merge_requests/1129>`_)
- Fix testing of rook ceph block storage classes
  - Now all configured rook ceph block storage pools for which a storage class is
  configured are checked rather than only `rook-ceph-data`. (`!1130 <https://gitlab.com/yaook/k8s/-/merge_requests/1130>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Include missing information in the "new Vault" case in the "Pivot vault" section of the Vault documentation (`!1086 <https://gitlab.com/yaook/k8s/-/merge_requests/1086>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Drop support for Kubernetes v1.25 (`!1056 <https://gitlab.com/yaook/k8s/-/merge_requests/1056>`_)
- Support for the manifest-based Calico installation has been dropped (`!1084 <https://gitlab.com/yaook/k8s/-/merge_requests/1084>`_)


Other Tasks
~~~~~~~~~~~

- Add hotfixing strategy (`!1063 <https://gitlab.com/yaook/k8s/-/merge_requests/1063>`_)
- Add deprecation policy. (`!1076 <https://gitlab.com/yaook/k8s/-/merge_requests/1076>`_)
- Prevent CI jobs from failing if there are volume snapshots left (`!1091 <https://gitlab.com/yaook/k8s/-/merge_requests/1091>`_)
- Fix releasenote-file-check in ci (`!1096 <https://gitlab.com/yaook/k8s/-/merge_requests/1096>`_)
- Refine hotfixing procedure (`!1101 <https://gitlab.com/yaook/k8s/-/merge_requests/1101>`_)
- We define how long we'll support older releases. (`!1112 <https://gitlab.com/yaook/k8s/-/merge_requests/1112>`_)
- Update flake dependencies (`!1117 <https://gitlab.com/yaook/k8s/-/merge_requests/1117>`_)


Misc
~~~~

- `!1082 <https://gitlab.com/yaook/k8s/-/merge_requests/1082>`_, `!1123 <https://gitlab.com/yaook/k8s/-/merge_requests/1123>`_, `!1128 <https://gitlab.com/yaook/k8s/-/merge_requests/1128>`_


v2.1.1 (2024-03-01)
-------------------

Bugfixes
~~~~~~~~

- Fix kubernetes-validate installation for K8s updates (`!1097 <https://gitlab.com/yaook/k8s/-/merge_requests/1097>`_)


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
  information, see the  :doc:`updated vault documentation </user/guide/vault/vault>`
  (`!1016 <https://gitlab.com/yaook/k8s/-/merge_requests/1016>`_).


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

  Note that you **must** update the vault policies once. See :doc:`Wireguard documentation </user/explanation/vpn/wireguard>` for further information.

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

  This will create new service names for thanos in K8s.
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
:doc:`as usual </user/guide/kubernetes/upgrading-kubernetes>`
via:

.. code:: shell

   # Replace the patch version
   MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.25.10

.. note::

   By default, the Tigera operator is deployed with Kubernetes
   v1.25. Therefore, during the upgrade from Kubernetes v1.24 to v1.25, the
   migration to the Tigera operator
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

[1] :doc:`GPU Support Documentation</user/explanation/gpu-and-vgpu>`

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
:doc:`Calico documentation </user/explanation/services/calico>` for further
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
:doc:`Upgrading Kubernetes documentation </user/guide/kubernetes/upgrading-kubernetes>`.

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
:doc:`Upgrading Kubernetes documentation </user/guide/kubernetes/upgrading-kubernetes>`.

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
separate action script.
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
``init.sh``-script!
The ``init.sh``-script will move your enabled submodules into the
``submodules/`` directory. Otherwise at least the symlink to the
``ch-role-users``- `role <https://gitlab.com/yaook/k8s/-/blob/devel/k8s-base/roles/ch-role-users>`__ will be
broken.

 .. note::

   By re-executing the ``init.sh``, the latest ``devel``
   branch of the ``managed-k8s``-module will be checked out under normal
   circumstances!
