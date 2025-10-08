{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  modules-lib = import ../../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkRemovedOptionModule mkRenamedResourceOptionModule mkMultiResourceOptionsModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types isValidSemver2;
  inherit (yk8s-lib.options) mkHelmChartVersionOption;
in {
  imports = [
    ./grafana.nix
    ./thanos.nix

    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "use_jsonnet_setup"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "migrate_from_v1"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "alertmanager_config_secret"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "alertmanager_configuration_name"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "kube_state_metrics_metric_annotation_allow_list"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "prometheus_monitor_all_namespaces"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "monitor_all_namespaces"] "")

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

        kube_state_metrics.memory.limit = "128Mi";
        kube_state_metrics.cpu.request = "50m";
      };
    })
    (mkRenamedResourceOptionModule ["k8s-service-layer" "prometheus"] [
      "operator"
      "alertmanager"
      "prometheus"
      "kube_state_metrics"
    ])
  ];

  options.yk8s.k8s-service-layer.prometheus = mkTopSection {
    _docs.preface = builtins.readFile ./preface.rst;

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
      type = types.yk8s.helm.chartRepoUrl;
      default = "https://prometheus-community.github.io/helm-charts";
    };

    prometheus_stack_chart_name = mkOption {
      type = types.yk8s.helm.chartRef;
      default = "kube-prometheus-stack";
    };

    prometheus_stack_release_name = mkOption {
      type = types.yk8s.helm.chartReleaseName;
      default = "prometheus-stack";
    };

    prometheus_adapter_release_name = mkOption {
      type = types.yk8s.helm.chartReleaseName;
      default = "prometheus-adapter";
    };

    remote_writes = mkOption {
      default = [];
      type = with types;
        listOf (
          submodule {
            options = {
              url = mkOption {
                type = types.yk8s.networking.httpxUrl;
                example = "http://remote-write-receiver:9090/api/v1/write";
              };
              basic_auth_secret_name = mkOption {
                description = ''
                  Name of the secret containing htpasswd for basic authentication of Prometheus remote write.
                  The secret must contain the following keys:
                  - username: FOO
                  - password: BAR
                '';
                type = types.yk8s.k8s.secretName;
              };
              write_relabel_configs = mkOption {
                description = ''
                  A list of RelabelConfigs, see
                  https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md#monitoring.coreos.com/v1.RelabelConfig
                '';
                type = with types;
                  listOf (submodule {
                    options = {
                      sourceLabels = mkOption {
                        default = null;
                        type = nullOr (listOf yk8s.prometheus.labelName);
                      };
                      separator = mkOption {
                        default = null;
                        type = nullOr str;
                      };
                      targetLabel = mkOption {
                        default = null;
                        type = nullOr yk8s.prometheus.labelName;
                      };
                      regex = mkOption {
                        default = null;
                        type = nullOr nonEmptyStr;
                      };
                      modulus = mkOption {
                        default = null;
                        type = nullOr ints.unsigned;
                      };
                      replacement = mkOption {
                        default = null;
                        type = nullOr nonEmptyStr;
                      };
                      action = mkOption {
                        default = null;
                        type = nullOr nonEmptyStr;
                      };
                    };
                  });
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

    nvidia_dcgm_exporter_helm_repo_url = mkOption {
      type = types.yk8s.helm.chartRepoUrl;
      default = "https://nvidia.github.io/dcgm-exporter/helm-charts";
    };

    nvidia_dcgm_exporter_helm_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=dcgm-exporter registryUrl=https://nvidia.github.io/dcgm-exporter/helm-charts
      default = "4.8.3";
    };

    monitoring_internet_probe = mkEnableOption ''
      adding blackbox-exporter to test basic internet connectivity
    '';
    node_exporter_textfile_collector_path = mkOption {
      type = types.yk8s.posix.absolutePath;
      default = "/var/lib/node_exporter/textfile_collector";
    };
    prometheus_stack_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=kube-prometheus-stack registryUrl=https://prometheus-community.github.io/helm-charts
      default = "84.5.0";
    };
    prometheus_adapter_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=prometheus-adapter registryUrl=https://prometheus-community.github.io/helm-charts
      default = "5.3.0";
    };

    namespace = mkOption {
      description = ''
        Namespace to deploy the monitoring in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.yk8s.k8s.namespaceName;
      default = "monitoring";
    };

    prometheus_service_name = mkOption {
      type = types.yk8s.k8s.serviceName;
      default = "prometheus-operated";
    };

    prometheus_persistent_storage_class = mkOption {
      description = ''
        Configure persistent storage for Prometheus
        By default an empty-dir is used.
        https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md
      '';
      type = with types; nullOr yk8s.k8s.storageClassName;
      default = null;
    };

    prometheus_persistent_storage_resource_request = mkOption {
      description = ''
        Configure persistent storage for Prometheus
        https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/storage.md
      '';
      type = types.yk8s.k8s.quantity;
      default = "50Gi";
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
      type = with types; nullOr yk8s.k8s.label;
      default = null;
      example = lib.options.literalExpression "\"\${scheduling_key_prefix}/monitoring\"";
    };
    internet_probe = mkEnableOption ''
      scraping external targets via blackbox exporter
      https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
    '';
    blackbox_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=prometheus-blackbox-exporter registryUrl=https://prometheus-community.github.io/helm-charts
      default = "11.16.0";
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
            type = types.yk8s.k8s.objectName;
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
              types.yk8s.networking.httpxUrl
              types.yk8s.networking.ipv4Addr
              types.yk8s.networking.ipv6Addr
              types.yk8s.networking.ipv4AddrWithPort
              types.yk8s.networking.ipv6AddrWithPort
            ];
            example = "http://example.com/healthz";
          };
          interval = mkOption {
            description = ''
              Scraping interval. Overrides value set in `defaults`
            '';
            type = types.yk8s.prometheus.intervalStr;
            default = "60s";
          };

          scrapeTimeout = mkOption {
            description = ''
              Scrape timeout. Overrides value set in `defaults`
            '';
            type = types.yk8s.prometheus.timeoutStr;
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
      type = types.yk8s.k8s.labelAttrs;
      default = {
      };
      example = {
        managed-by = "yaook-k8s";
      };
    };
  };
  config.yk8s._targets.ansible.assertions =
    [
      {
        assertion = isValidSemver2 cfg.prometheus_stack_version -> lib.versionAtLeast cfg.prometheus_stack_version "68.4.0";
        message = "config.yk8s.k8s-service-layer.prometheus.prometheus_stack_version: '${cfg.prometheus_stack_version}' must be at least 68.4.0";
      }
    ]
    # check that no IPv6 module is configured in any probe if yk8s.infra.ipv6_enabled is disabled
    ++ lib.imap0
    (i: x: let
      idx = toString i;
    in {
      assertion = cfg.internet_probe -> ! config.yk8s.infra.ipv6_enabled -> ! lib.strings.hasSuffix "_v6" x.module;
      message = "config.yk8s.k8s-service-layer.prometheus.internet_probe_targets[${idx}].module: ${x.module} is an IPv6-specific module but config.yk8s.infra.ipv6_enabled=false";
    })
    cfg.internet_probe_targets;
  config.yk8s._targets.ansible.warnings =
    []
    ++ lib.optional (!(isValidSemver2 cfg.prometheus_stack_version)) ''
      config.yk8s.k8s-service-layer.prometheus.prometheus_stack_version: '${cfg.prometheus_stack_version}' not in semver2 format
      Please make sure that '${cfg.prometheus_stack_version}' has a version level of at least 68.4.0.
    '';
  config.yk8s._targets.ansible.inventory_packages = [
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
