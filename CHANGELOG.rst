Releasenotes
============

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.0.0/>`__,
and this project will adhere to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`__.

We use `towncrier <https://github.com/twisted/towncrier>`__ for the
generation of our release notes file.

Information about unreleased changes can be found
`here <https://gitlab.com/yaook/k8s/-/tree/devel/docs/_releasenotes?ref_type=heads>`__.

.. towncrier release notes start

v10.1.0 (2025-08-27)
--------------------

New Features
~~~~~~~~~~~~

- Added :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.addressing_style` to configure the addressing style of the etcd-backup bucket. (`!1931 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1931>`_)
- Added :ref:`configuration-options.yk8s.k8s-service-layer.vault.backup_s3_addressing_style` to configure the addressing style of the vault-backup bucket. (`!1938 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1938>`_)
- The options to configure helm chart versions have been streamlined.
  From now on, ``null`` can be supplied to unpin a helm chart and rollout the latest available version.

  * :ref:`configuration-options.yk8s.k8s-service-layer.cert-manager.chart_version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.chart_version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.ingress.chart_version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.blackbox_version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.nvidia_dcgm_exporter_helm_version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_adapter_version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.prometheus_stack_version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_chart_version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.rook.version`
  * :ref:`configuration-options.yk8s.k8s-service-layer.vault.chart_version`

  . (`!1945 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1945>`_)
- Added :ref:`configuration-options.yk8s.k8s-service-layer.vault.backup_s3_bucket` to configure the bucket name for vault backup. (`!1949 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1949>`_)
- Support for Kubernetes v1.33 has been added. (`!1982 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1982>`_)


Changed functionality
~~~~~~~~~~~~~~~~~~~~~

- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.1.1 to 11.2.0 (`!1976 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1976>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.2.0 to 11.2.1 (`!1988 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1988>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.2.0 to 4.4.0 (`!1993 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1993>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.4.0 to 4.4.1 (`!2007 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2007>`_)
- Updated default version of helm chart ingress-nginx of https://github.com/kubernetes/ingress-nginx from 4.13.0 to 4.13.1 (`!2008 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2008>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.2.1 to 11.2.2 (`!2048 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2048>`_)
- Updated default version of helm chart prometheus-blackbox-exporter of https://github.com/prometheus-community/helm-charts from 11.2.2 to 11.3.0 (`!2054 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2054>`_)
- Updated default version of helm chart dcgm-exporter of https://github.com/nvidia/dcgm-exporter from 4.4.1 to 4.5.0 (`!2056 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2056>`_)


Bugfixes
~~~~~~~~

- In case the Kubernetes control plane nodes serve as frontend nodes
  we do not deploy an additional Prometheus node-exporter service monitor for frontend nodes anymore
  since the monitoring stack already provides one for all Kubernetes nodes. (`!1964 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1964>`_, `!1969 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1969>`_)


Changes in the Documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- The project has been renamed from YAOOK/K8s to TAROOK.
  Documentation including comments, links and images have been updated to reflect the new project name. (`!1868 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1868>`_, `!2005 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2005>`_)
- The example in :ref:`configuration-options.yk8s.containerd.mirrors` has been fixed. (`!1971 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1971>`_)
- Fixed the examples of config options
  that expect a `Nix path <https://nix.dev/manual/nix/2.25/language/types#type-path>`_. (`!1979 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1979>`_)
- The documentation points now to an automatically generated list of `supported releases <https://meta.docs.tarook.cloud/supported_releases.html>`_. (`!2003 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2003>`_)


Deprecations and Removals
~~~~~~~~~~~~~~~~~~~~~~~~~

- Support for Kubernetes v1.30 has been dropped. (`!1967 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1967>`_)


Other Tasks
~~~~~~~~~~~

- `!1959 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1959>`_, `!1963 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1963>`_, `!1965 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1965>`_, `!1968 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1968>`_, `!1980 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1980>`_, `!1981 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1981>`_, `!1987 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1987>`_, `!2049 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2049>`_, `!2052 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2052>`_, `!2059 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2059>`_, `!2060 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2060>`_


Misc
~~~~

- `!1962 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1962>`_, `!2057 <https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2057>`_
