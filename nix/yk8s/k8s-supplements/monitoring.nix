{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkRemovedOptionModule mkRenamedResourceOptionModules mkMultiResourceOptionsModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (lib.attrsets) foldlAttrs;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkMultiResourceOptions;
  inherit (yk8s-lib.types) k8sSize;
in {
  imports =
    [
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "use_jsonnet_setup" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "migrate_from_v1" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "alertmanager_config_secret" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "alertmanager_configuration_name" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "kube_state_metrics_metric_annotation_allow_list" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "thanos_metadata_volume_size" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "thanos_metadata_volume_storage_class" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "grafana_plugins" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "prometheus_monitor_all_namespaces" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "monitor_all_namespaces" "")

      (mkRenamedOptionModule "k8s-service-layer.prometheus" "prometheus_operator_cpu_request" "operator_resources.cpu.request")
      (mkRenamedOptionModule "k8s-service-layer.prometheus" "prometheus_operator_cpu_limit" "operator_resources.cpu.limit")
      (mkRenamedOptionModule "k8s-service-layer.prometheus" "prometheus_operator_memory_request" "operator_resources.memory.request")
      (mkRenamedOptionModule "k8s-service-layer.prometheus" "prometheus_operator_memory_limit" "operator_resources.memory.limit")

      (mkMultiResourceOptionsModule "k8s-service-layer.prometheus" {
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
    ]
    ++ (mkRenamedResourceOptionModules "k8s-service-layer.prometheus" [
      "operator"
      "alertmanager"
      "prometheus"
      "grafana"
      "kube_state_metrics"
      "thanos_sidecar"
      "thanos_query"
      "thanos_compact"
      "thanos_store"
    ]);

  options.yk8s.k8s-service-layer.prometheus = mkTopSection {
    _docs.preface = ''
      .. _cluster-configuration.prometheus-configuration:

      Prometheus-based Monitoring Configuration
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      The used prometheus-based monitoring setup will be explained in more
      detail soon :)

      .. note::

        To enable prometheus,
        ``k8s-service-layer.prometheus.install`` and
        ``kubernetes.monitoring.enabled`` need to be set to ``true``.


      Tweak Thanos Configuration
      """"""""""""""""""""""""""

      index-cache-size / in-memory-max-size
      *************************************

      Thanos is unaware of its Kubernetes limits
      which can lead to OOM kills of the storegateway
      if a lot of metrics are requested.

      We therefore added an option to configure the
      ``index-cache-size``
      (see `Tweak Thanos configuration (!1116) · Merge requests · YAOOK / k8s · GitLab <https://gitlab.com/yaook/k8s/-/merge_requests/1116/diffs>`__
      and (see `Thanos - Highly available Prometheus setup with long term storage capabilities <https://thanos.io/tip/components/store.md/#in-memory-index-cache>`__)
      which should prevent that and is available as of `release/v3.0 · YAOOK / k8s · GitLab <https://gitlab.com/yaook/k8s/-/blob/release/v3.0/CHANGELOG.rst>`__.

      It can be configured by setting
      the following configuration options:

      .. code:: nix

        k8s-service-layer.prometheus.thanos_store_in_memory_max_size = "XGB";
        k8s-service-layer.prometheus.thanos_store_memory_request = "XGi";
        k8s-service-layer.prometheus.thanos_store_memory_limit = "XGi";

      Note that the value must be a decimal unit!
      Please also note that you should set a meaningful value
      based on the configured ``thanos_store_memory_limit``.
      If this variable is not explicitly configured,
      the helm chart default is used which is not optimal.
      You should configure both variables and in the best
      case you additionally set ``thanos_store_memory_request``
      to the same value as ``thanos_store_memory_limit``.

      Persistence
      ***********

      With `release/v3.0 · YAOOK / k8s · GitLab <https://gitlab.com/yaook/k8s/-/blob/release/v3.0/CHANGELOG.rst>`__,
      persistence for Thanos components has been reworked.
      By default, Thanos components use emptyDirs.
      Depending on the size of the cluster and the metrics
      flying around, Thanos components may need more disk
      than the host node can provide them and in that cases
      it makes sense to configure persistence.

      If you want to enable persistence for Thanos components,
      you can do so by configuring a storage class
      to use and you can specify the persistent volume
      size for each component like in the following.

      .. code:: nix

        k8s-service-layer.prometheus.thanos_storage_class = "SOME_STORAGE_CLASS";
        k8s-service-layer.prometheus.thanos_storegateway_size = "XGi";
        k8s-service-layer.prometheus.thanos_compactor_size = "YGi";

      Options
      *******

    '';

    install = mkOption {
      description = ''
        If kubernetes.monitoring.enabled is true, choose whether to install or uninstall
        Prometheus. IF SET TO FALSE, PROMETHEUS WILL BE DELETED WITHOUT CHECKING FOR
        DISRUPTION (sic!).
      '';
      type = types.bool;
      default = true;
    };

    prometheus_stack_version = mkOption {
      description = ''
        helm chart version of the prometheus stack
        https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
        If you set this empty (not unset), the latest version is used
        Note that upgrades require additional steps and maybe even LCM changes are needed:
        https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#upgrading-chart
      '';
      type = types.nonEmptyStr;
      default = "59.1.0";
    };
    prometheus_adapter_version = mkOption {
      type = types.nonEmptyStr;
      default = "4.10.0";
    };

    namespace = mkOption {
      description = ''
        Namespace to deploy the monitoring in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.nonEmptyStr;
      default = "monitoring";
    };

    prometheus_service_name = mkOption {
      type = types.nonEmptyStr;
      default = "prometheus-operated";
    };

    prometheus_persistent_storage_class = mkOption {
      description = ''
        Configure persistent storage for Prometheus
        By default an empty-dir is used.
        https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
    };

    prometheus_persistent_storage_resource_request = mkOption {
      description = ''
        Configure persistent storage for Prometheus
        https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md
      '';
      type = k8sSize;
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
      type = with types; nullOr nonEmptyStr;
      default = null;
    };

    grafana_persistent_storage_class = mkOption {
      description = ''
        If this variable is defined, Grafana will store its data in a PersistentVolume
        in the defined StorageClass. Otherwise, persistence is disabled for Grafana.
        The value has to be a valid StorageClass available in your cluster.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
    };

    use_thanos = mkEnableOption "use of Thanos";

    manage_thanos_bucket = mkOption {
      description = ''
        Let terraform create an object storage container / bucket for you if `true`.
        If set to `false` one must provide a valid configuration via Vault
        See: https://yaook.gitlab.io/k8s/release/v3.0/managed-services/prometheus/prometheus-stack.html#custom-bucket-management
      '';
      type = types.bool;
      default = true;
    };

    thanos_chart_version = mkOption {
      description = ''
        Set custom Bitnami/Thanos chart version
      '';
      type = types.str;
      default = "15.5.0";
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
      type = with types; nullOr nonEmptyStr;
      default = null;
    };

    thanos_storegateway_size = mkOption {
      description = ''
        You can explicitly set the PV size for each component.
        If left undefined, the helm chart defaults will be used
      '';
      type = with types; nullOr k8sSize;
      default = null;
    };

    thanos_compactor_size = mkOption {
      description = ''
        You can explicitly set the PV size for each component.
        If left undefined, the helm chart defaults will be used
      '';
      type = with types; nullOr k8sSize;
      default = null;
    };

    alertmanager_replicas = mkOption {
      description = ''
        How many replicas of the alertmanager should be deployed inside the cluster
      '';
      type = types.ints.positive;
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
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "\${config.yk8s.node-scheduling.scheduling_key_prefix}/monitoring";
    };
    thanos_store_in_memory_max_size = mkOption {
      description = ''
        https://thanos.io/tip/components/store.md/#in-memory-index-cache
        Note: Unit must be specified as decimal! (MB,GB)
        This value should be chosen in a sane matter based on
        thanos_store_memory_request and thanos_store_memory_limit
      '';
      type = with types; nullOr strMatching "([0-9]+[MG]B)";
      default = null;
    };
    thanos_objectstorage_container_name = mkOption {
      type = types.nonEmptyStr;
      default = "${config.yk8s.terraform.cluster_name}-monitoring-thanos-data";
      defaultText = "\${config.yk8s.terraform.cluster_name}-monitoring-thanos-data";
    };
    thanos_objectstorage_config_file = mkOption {
      type = with types; nullOr nonEmptyStr;
      default = null;
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
      type = with types; listOf nonEmptyStr;
      default = [];
    };
    blackbox_version = mkOption {
      description = ''
        Deploy a specific blackbox exporter version
        https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
      '';
      type = types.nonEmptyStr;
      default = "7.0.0";
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
              Human readable URL that will appear in Prometheus / AlertManager
            '';
            type = types.nonEmptyStr;
          };
          url = mkOption {
            description = ''
              The URL that blackbox will scrape
            '';
            type = types.nonEmptyStr;
            example = "http://example.com/healthz";
          };
          interval = mkOption {
            description = ''
              Scraping interval. Overrides value set in `defaults`
            '';
            type = types.nonEmptyStr;
            default = "60s";
          };

          scrapeTimeout = mkOption {
            description = ''
              Scrape timeout. Overrides value set in `defaults`
            '';
            type = types.nonEmptyStr;
            default = "60s";
          };
          module = mkOption {
            description = ''
              module to be used. Can be "http_2xx" (default), "http_api" (allow status codes 200, 300, 401), "http_api_insecure", "icmp" or "tcp_connect".
            '';
            type = types.strMatching "http_2xx|http_api(_insecure)?|icmp|tcp_connect";
            default = "http_2xx";
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
      type = with types; attrsOf nonEmptyStr;
      default = {
        managed-by = "yaook-k8s";
      };
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "monitoring_";
      inventory_path = "all/prometheus.yaml";
      unflat = ["common_labels"];
    })
  ];
}
