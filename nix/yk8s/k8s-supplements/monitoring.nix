{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkRemovedOptionModule mkRenamedResourceOptionModule mkMultiResourceOptionsModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (lib.attrsets) foldlAttrs;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkMultiResourceOptions;
  inherit (yk8s-lib.options) mkHelmChartVersionOption;
  inherit
    (yk8s-lib.types)
    absolutePosixPath
    bytesPower10
    helmChartReleaseName
    helmChartRepoUrl
    helmChartRef
    httpxHostPathUrl
    httpxUrl
    ipv4Addr
    ipv4AddrWithPort
    ipv6Addr
    ipv6AddrWithPort
    k8sLabel
    k8sLabelAttrs
    k8sNamespaceName
    k8sObjectName
    k8sQuantity
    k8sSecretName
    k8sServiceName
    k8sStorageClassName
    openstackSwiftContainerName
    prometheusIntervalStr
    prometheusTimeoutStr
    prometheusRelabelConfig
    relativePosixPath
    subdomainLabel
    ;
in {
  imports = [
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "use_jsonnet_setup"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "use_helm_thanos"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "migrate_from_v1"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "alertmanager_config_secret"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "alertmanager_configuration_name"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "kube_state_metrics_metric_annotation_allow_list"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_metadata_volume_size"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_metadata_volume_storage_class"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "grafana_plugins"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "prometheus_monitor_all_namespaces"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "monitor_all_namespaces"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_objectstorage_config_path"] "Use `thanos_objectstorage_config_file` instead.")

    (mkRenamedOptionModule ["k8s-service-layer" "prometheus" "prometheus_operator_cpu_request"] ["k8s-service-layer" "prometheus" "operator_resources" "cpu" "request"])
    (mkRenamedOptionModule ["k8s-service-layer" "prometheus" "prometheus_operator_cpu_limit"] ["k8s-service-layer" "prometheus" "operator_resources" "cpu" "limit"])
    (mkRenamedOptionModule ["k8s-service-layer" "prometheus" "prometheus_operator_memory_request"] ["k8s-service-layer" "prometheus" "operator_resources" "memory" "request"])
    (mkRenamedOptionModule ["k8s-service-layer" "prometheus" "prometheus_operator_memory_limit"] ["k8s-service-layer" "prometheus" "operator_resources" "memory" "limit"])

    (mkMultiResourceOptionsModule ["k8s-service-layer" "prometheus"] {
      description = ''
        PROMETHEUS POD RESOURCE LIMITS
        The following limits are applied to the respective pods.
        Note that the Prometheus limits are chosen fairly conservatively and may need
        tuning for larger and smaller clusters.
        By default, we prefer to set limits in such a way that the Pods end up in the
        Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
        same value).
      '';
      resources = {
        operator.memory.limit = "400Mi";
        operator.cpu.request = "100m";

        alertmanager.memory.limit = "256Mi";
        alertmanager.cpu.request = "100m";

        prometheus.memory.limit = "3Gi";
        prometheus.cpu.request = "1";

        grafana.memory.limit = "512Mi";
        grafana.cpu.request = "100m";
        grafana.cpu.example = "500m";

        kube_state_metrics.memory.limit = "128Mi";
        kube_state_metrics.cpu.request = "50m";

        thanos_sidecar.memory.limit = "256Mi";
        thanos_sidecar.cpu.request = "500m";

        thanos_query.memory.limit = "786Mi";
        thanos_query.cpu.request = "100m";
        thanos_query.cpu.example = "1";

        thanos_compact.memory.limit = "200Mi";
        thanos_compact.cpu.request = "100m";

        thanos_store.memory.limit = "2Gi";
        thanos_store.cpu.request = "100m";
        thanos_store.cpu.example = "500m";
      };
    })
    (mkRenamedResourceOptionModule ["k8s-service-layer" "prometheus"] [
      "operator"
      "alertmanager"
      "prometheus"
      "grafana"
      "kube_state_metrics"
      "thanos_sidecar"
      "thanos_query"
      "thanos_compact"
      "thanos_store"
    ])
  ];

  options.yk8s.k8s-service-layer.prometheus = mkTopSection {
    _docs.preface = ''
      The used prometheus-based monitoring setup will be explained in more
      detail soon :)

      .. note::

        To enable prometheus,
        :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.install`
        and
        :ref:`configuration-options.yk8s.kubernetes.monitoring.enabled`
        need to be set to ``true``.


      Tweak Thanos Configuration
      """"""""""""""""""""""""""

      index-cache-size / in-memory-max-size
      *************************************

      Thanos is unaware of its Kubernetes limits
      which can lead to OOM kills of the storegateway
      if a lot of metrics are requested.

      This can be prevented by tuning the following config options:

        - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_in_memory_max_size`
        - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.limits.memory`
        - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_store_resources.requests.memory`

      Note that the value must be a decimal unit!
      Please also note that
      if no explicit memory limit is configured
      the helm chart default is used which is not optimal.
      You should configure both memory limit and request
      which are recommended to have the same value.

      Persistence
      ***********

      With `release/v3.0 · Tarook · GitLab <https://gitlab.com/alasca.cloud/tarook/tarook/-/blob/release/v3.0/CHANGELOG.rst>`__,
      persistence for Thanos components has been reworked.
      By default, Thanos components use emptyDirs.
      Depending on the size of the cluster and the metrics
      flying around, Thanos components may need more disk
      than the host node can provide them and in that cases
      it makes sense to configure persistence.

      If you want to enable persistence for Thanos components,
      you can do so by configuring a storage class
      to use and you can specify the persistent volume
      size for each component with the following config options:

        - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storage_class`
        - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_storegateway_size`
        - :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.thanos_compactor_size`

      .. _cluster-configuration.prometheus-configuration.updating-immutable-options:

      Updating immutable options
      **************************

      Some options are immutable when deployed.
      If you want to change them nonetheless, follow these manual steps:
      1. Increase the size of the corresponding PVC
      2. Delete the stateful set: ``kubectl delete -n monitoring sts --cascade=false thanos-<storegateway|compactor>``
      3. Re-deploy it with the LCM: ``AFLAGS="--diff --tags thanos" bash managed-k8s/actions/apply-k8s-supplements.sh``
    '';

    install = mkOption {
      description = ''
        If :ref:`configuration-options.yk8s.kubernetes.monitoring.enabled` is ``true``, choose whether to install or uninstall
        Prometheus. IF SET TO FALSE, PROMETHEUS WILL BE DELETED WITHOUT CHECKING FOR
        DISRUPTION (sic!).
      '';
      type = types.bool;
      default = true;
    };

    prometheus_helm_repo_url = mkOption {
      type = helmChartRepoUrl;
      default = "https://prometheus-community.github.io/helm-charts";
    };

    prometheus_stack_chart_name = mkOption {
      type = helmChartRef;
      default = "kube-prometheus-stack";
    };

    prometheus_stack_release_name = mkOption {
      type = helmChartReleaseName;
      default = "prometheus-stack";
    };

    prometheus_adapter_release_name = mkOption {
      type = helmChartReleaseName;
      default = "prometheus-adapter";
    };

    remote_writes = mkOption {
      default = [];
      type = with types;
        listOf (
          submodule {
            options = {
              url = mkOption {
                type = httpxUrl;
                example = "http://remote-write-receiver:9090/api/v1/write";
              };
              basic_auth_secret_name = mkOption {
                description = ''
                  Name of the secret containing htpasswd for basic authentication of Prometheus remote write.
                  The secret must contain the following keys:
                  - username: FOO
                  - password: BAR
                '';
                type = k8sSecretName;
              };
              write_relabel_configs = mkOption {
                description = ''
                  A list of RelabelConfigs, see
                  https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md#monitoring.coreos.com/v1.RelabelConfig
                '';
                type = with types; listOf prometheusRelabelConfig;
                example = [
                  {
                    targetLabel = "prometheus";
                    replacement = "my-cluster";
                  }
                  {
                    targetLabel = "cluster";
                    replacement = "my-cluster";
                  }
                ];
              };
            };
          }
        );
    };

    grafana_admin_secret_name = mkOption {
      type = k8sSecretName;
      default = "cah-grafana-admin";
    };

    grafana_dashboard_enable_multicluster_support = mkEnableOption ''
      referencing multiple K8s clusters by a single Grafana datasource.
    '';

    nvidia_dcgm_exporter_helm_repo_url = mkOption {
      type = helmChartRepoUrl;
      default = "https://nvidia.github.io/dcgm-exporter/helm-charts";
    };

    nvidia_dcgm_exporter_helm_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=dcgm-exporter registryUrl=https://nvidia.github.io/dcgm-exporter/helm-charts
      default = "4.5.0";
    };

    monitoring_internet_probe = mkEnableOption ''
      adding blackbox-exporter to test basic internet connectivity
    '';
    node_exporter_textfile_collector_path = mkOption {
      type = absolutePosixPath;
      default = "/var/lib/node_exporter/textfile_collector";
    };
    prometheus_stack_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=kube-prometheus-stack registryUrl=https://prometheus-community.github.io/helm-charts
      default = "77.8.0";
    };
    prometheus_adapter_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=prometheus-adapter registryUrl=https://prometheus-community.github.io/helm-charts
      default = "4.14.2";
    };

    namespace = mkOption {
      description = ''
        Namespace to deploy the monitoring in (will be created if it does not exist, but
        never deleted).
      '';
      type = k8sNamespaceName;
      default = "monitoring";
    };

    prometheus_service_name = mkOption {
      type = k8sServiceName;
      default = "prometheus-operated";
    };

    prometheus_persistent_storage_class = mkOption {
      description = ''
        Configure persistent storage for Prometheus
        By default an empty-dir is used.
        https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md
      '';
      type = with types; nullOr k8sStorageClassName;
      default = null;
    };

    prometheus_persistent_storage_resource_request = mkOption {
      description = ''
        Configure persistent storage for Prometheus
        https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md
      '';
      type = k8sQuantity;
      default = "50Gi";
    };

    use_grafana = mkOption {
      description = "Enable grafana";
      type = types.bool;
      default = true;
    };

    grafana_root_url = mkOption {
      description = ''
        The full public facing url you use in browser, used for redirects and emails
      '';
      type = with types; nullOr httpxHostPathUrl;
      default = null;
    };

    grafana_persistent_storage_class = mkOption {
      description = ''
        If this variable is defined, Grafana will store its data in a PersistentVolume
        in the defined StorageClass. Otherwise, persistence is disabled for Grafana.
        The value has to be a valid StorageClass available in your cluster.
      '';
      type = with types; nullOr k8sStorageClassName;
      default = null;
    };

    use_thanos = mkEnableOption "use of Thanos";

    manage_thanos_bucket = mkOption {
      description = ''
        Let terraform create an object storage container / bucket for you if `true`.
        If set to `false` one must provide a valid configuration via Vault.
        See :ref:`thanos.custom-bucket-management` for details.
      '';
      type = types.bool;
      default = true;
    };

    thanos_chart_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=thanos registryUrl=https://charts.bitnami.com/bitnami
      default = "17.2.3";
    };

    thanos_storage_class = mkOption {
      description = ''
        Thanos uses emptyDirs by default for its components
        for faster access.
        If that's not feasible, a storage class can be set to
        enable persistence and the size for each component volume
        can be configured.
        Note that switching between persistence requires
        manual intervention and it may be necessary to reinstall
        the helm chart completely.
      '';
      type = with types; nullOr k8sStorageClassName;
      default = null;
    };

    thanos_storegateway_size = mkOption {
      description = ''
        You can explicitly set the PV size for each component.
        If left undefined, the helm chart defaults will be used

        Immutable when deployed. (See also :ref:`cluster-configuration.prometheus-configuration.updating-immutable-options`)
      '';
      type = with types; nullOr k8sQuantity;
      default = null;
    };

    thanos_compactor_size = mkOption {
      description = ''
        You can explicitly set the PV size for each component.
        If left undefined, the helm chart defaults will be used

        Immutable when deployed. (See also :ref:`cluster-configuration.prometheus-configuration.updating-immutable-options`)
      '';
      type = with types; nullOr k8sQuantity;
      default = null;
    };

    alertmanager_replicas = mkOption {
      description = ''
        How many replicas of the alertmanager should be deployed inside the cluster
      '';
      type = types.ints.unsigned;
      default = 1;
    };

    scheduling_key = mkOption {
      description = ''
        Scheduling keys control where services may run. A scheduling key corresponds
        to both a node label and to a taint. In order for a service to run on a node,
        it needs to have that label key.
        If no scheduling key is defined for service, it will run on any untainted
        node.
      '';
      type = with types; nullOr k8sLabel;
      default = null;
      example = lib.options.literalExpression "\"\${scheduling_key_prefix}/monitoring\"";
    };
    thanos_store_in_memory_max_size = mkOption {
      description = ''
        https://thanos.io/tip/components/store.md/#in-memory-index-cache
        Note: Unit must be specified as decimal! (MB,GB)
        This value should be chosen in a sane matter based on
        thanos_store_memory_request and thanos_store_memory_limit
      '';
      type = with types; nullOr bytesPower10;
      default = null;
    };
    thanos_objectstorage_container_name = mkOption {
      type = openstackSwiftContainerName;
      default = "${config.yk8s.infra.cluster_name}-monitoring-thanos-data";
      defaultText = "\${config.yk8s.infra.cluster_name}-monitoring-thanos-data";
    };
    thanos_objectstorage_config_file = mkOption {
      description = ''
        Note: The given path is interpreted as being relative to the cluster repo's config directory.
      '';
      # NOTE: Not using `pathInStore` here because the expected file contains secrets
      # TODO: Eliminate config option and store secrets solely in Vault
      type = with types; nullOr relativePosixPath;
      default = null;
      example = "./monitoring/thanos_objectstorage.config";
    };
    internet_probe = mkEnableOption ''
      scraping external targets via blackbox exporter
      https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
    '';
    thanos_query_additional_store_endpoints = mkOption {
      description = ''
        Provide a list of DNS endpoints for additional thanos store endpoints.
        The endpoint will be extended to `dnssrv+_grpc._tcp.{{ endpoint }}.monitoring.svc.cluster.local`.
      '';
      type = with types; listOf subdomainLabel;
      default = [];
    };
    blackbox_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=prometheus-blackbox-exporter registryUrl=https://prometheus-community.github.io/helm-charts
      default = "11.3.1";
    };
    allow_external_rules = mkEnableOption ''
      external rules.
      By default, prometheus and alertmanager only consider global rules from the monitoring
      namespace while other rules can only alert on their own namespace. If this variable is
      set, cluster wide rules are considered from all namespaces.
    '';
    internet_probe_targets = mkOption {
      default = [];
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            description = ''
              Pretty name that will appear in Prometheus / AlertManager
            '';
            # NOTE: This value is used in the prometheus-blackbox-exporter helm chart
            #       where it ends up in the metadata.name field of the ServiceMonitor Kubernetes object.
            #       See https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/1731#note_2635298999
            type = k8sObjectName;
          };
          url = mkOption {
            # see https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus-blackbox-exporter/values.yaml#L327
            #  and https://github.com/prometheus/blackbox_exporter/blob/master/CONFIGURATION.md#module
            description = ''
              The URL that blackbox will scrape

              Depending on
              :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module`
              this needs to be a
              HTTP URL (http_*),
              IP address (icmp)
              or IP address with port (tcp_connect).
            '';
            type = types.oneOf [
              httpxUrl
              ipv4Addr
              ipv6Addr
              ipv4AddrWithPort
              ipv6AddrWithPort
            ];
            example = "http://example.com/healthz";
          };
          interval = mkOption {
            description = ''
              Scraping interval. Overrides value set in `defaults`
            '';
            type = prometheusIntervalStr;
            default = "60s";
          };

          scrapeTimeout = mkOption {
            description = ''
              Scrape timeout. Overrides value set in `defaults`
            '';
            type = prometheusTimeoutStr;
            default = "60s";
          };
          module = mkOption {
            description = ''
              The module to be used for the probe.

              Defaults to ``http_2xx`` if :ref:`configuration-options.yk8s.infra.ipv4_enabled` is ``true``.
              Otherwise, defaults to ``http_2xx_v6`` if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is ``true``.

              Modules without the ``_v6`` suffix use IPv4 as preferred protocol.
              IPv6-specific modules (indicated by the ``_v6`` suffix) are only available
              if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is enabled.
              They use IPv6 as preferred protocol.

              For example, if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is enabled,
              you could use the module ``http_api_v6`` to probe the target
              which allows HTTP status codes 200, 300, 400 and 401.
            '';
            type = types.enum [
              "http_2xx"
              "http_api"
              "http_api_insecure"
              "icmp"
              "tcp_connect"
              "http_2xx_v6"
              "http_api_v6"
              "http_api_insecure_v6"
              "icmp_v6"
              "tcp_connect_v6"
            ];
            default =
              if config.yk8s.infra.ipv4_enabled
              then "http_2xx"
              else if config.yk8s.infra.ipv6_enabled
              then "http_2xx_v6"
              else throw "yk8s.k8s-service-layer.prometheus.internet_probe_targets.*.module: unable to choose default. This is likely a bug"; # should never happen
          };
        };
      });
    };
    common_labels = mkOption {
      description = ''
        If at least one common_label is defined, Prometheus will be created with selectors
        matching these labels and only ServiceMonitors that meet the criteria of the selector,
        i.e. are labeled accordingly, are included by Prometheus.
        The LCM takes care that all ServiceMonitors created by itself are labeled accordingly.
        The key can not be "release" as that one is already used by the Prometheus helm chart.
      '';
      type = k8sLabelAttrs;
      default = {
      };
      example = {
        managed-by = "yaook-k8s";
      };
    };
  };
  config.yk8s.assertions =
    []
    # check that no IPv6 module is configured in any probe if yk8s.infra.ipv6_enabled is disabled
    ++ lib.imap0
    (i: x: let
      idx = builtins.toString i;
    in {
      assertion = cfg.internet_probe -> ! config.yk8s.infra.ipv6_enabled -> ! lib.strings.hasSuffix "_v6" x.module;
      message = "config.yk8s.k8s-service-layer.prometheus.internet_probe_targets[${idx}].module: ${x.module} is an IPv6-specific module but config.yk8s.infra.ipv6_enabled=false";
    })
    cfg.internet_probe_targets;
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "monitoring_";
      inventory_path = "all/prometheus.yaml";
      unflat = [
        ["common_labels"]
      ];
    })
  ];
}
