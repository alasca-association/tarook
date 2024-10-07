{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  modules-lib = import ../../lib/modules.nix {inherit lib;};
  inherit
    (modules-lib)
    mkRenamedOptionModule
    mkRemovedOptionModule
    mkRenamedResourceOptionModules
    mkMultiResourceOptionsModule
    mkHelmValuesModule
    ;
  inherit (lib) mkEnableOption mkOption types;
  inherit (lib.attrsets) foldlAttrs;
  inherit
    (yk8s-lib)
    mkTopSection
    mkGroupVarsFile
    mkMultiResourceOptions
    ;
  inherit (yk8s-lib.types) k8sSize;
in {
  imports =
    [
      ./thanos.nix

      (mkRemovedOptionModule "k8s-service-layer.prometheus" "use_jsonnet_setup" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "migrate_from_v1" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "alertmanager_config_secret" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "alertmanager_configuration_name" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "kube_state_metrics_metric_annotation_allow_list" "")
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
        };
      })
    ]
    ++ (mkRenamedResourceOptionModules "k8s-service-layer.prometheus" [
      "operator"
      "alertmanager"
      "prometheus"
      "grafana"
      "kube_state_metrics"
    ]);

  options.yk8s.k8s-service-layer.prometheus = mkTopSection {
    _docs.preface = builtins.readFile ./preface.rst;

    install = mkOption {
      description = ''
        If kubernetes.monitoring.enabled is true, choose whether to install or uninstall
        Prometheus. IF SET TO FALSE, PROMETHEUS WILL BE DELETED WITHOUT CHECKING FOR
        DISRUPTION (sic!).
      '';
      type = types.bool;
      default = true;
    };

    prometheus_helm_repo_url = mkOption {
      type = types.nonEmptyStr;
      default = "https://prometheus-community.github.io/helm-charts";
    };

    prometheus_stack_chart_name = mkOption {
      type = types.nonEmptyStr;
      default = "prometheus-community/kube-prometheus-stack";
    };

    prometheus_stack_release_name = mkOption {
      type = types.nonEmptyStr;
      default = "prometheus-stack";
    };

    prometheus_adapter_release_name = mkOption {
      type = types.nonEmptyStr;
      default = "prometheus-adapter";
    };

    remote_writes = mkOption {
      type = with types; listOf nonEmptyStr;
      default = [];
    };

    grafana_admin_secret_name = mkOption {
      type = types.nonEmptyStr;
      default = "cah-grafana-admin";
    };

    nvidia_dcgm_exporter_helm_repo_url = mkOption {
      type = types.nonEmptyStr;
      default = "https://nvidia.github.io/dcgm-exporter/helm-charts";
    };

    nvidia_dcgm_exporter_helm_version = mkOption {
      description = ''
        if not specified, latest
      '';
      type = types.str;
      default = "";
    };

    thanos_objectstorage_config_path = mkOption {
      type = types.nonEmptyStr;
      default = "{{ playbook_dir }}/../../../config";
    };

    monitoring_internet_probe = mkEnableOption ''
      adding blackbox-exporter to test basic internet connectivity
    '';
    node_exporter_textfile_collector_path = mkOption {
      type = types.nonEmptyStr;
      default = "/var/lib/node_exporter/textfile_collector";
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

    internet_probe = mkEnableOption ''
      scraping external targets via blackbox exporter
      https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
    '';
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
