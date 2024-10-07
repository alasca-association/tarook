{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  modules-lib = import ../../../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkHelmValuesModule;
  inherit (yk8s-lib) mkAffinity mkTolerations;
in {
  imports = [
    (mkHelmValuesModule "k8s-service-layer.prometheus" "prometheus_stack")

    ./grafana.nix
    ./prometheus.nix
  ];
  config.yk8s.k8s-service-layer.prometheus.prometheus_stack_default_values = let
    affinity = mkAffinity {inherit (cfg) scheduling_key;};
    tolerations = mkTolerations cfg.scheduling_key;
  in {
    commonLabels = cfg.common_labels;
    priorityClassName = "system-cluster-critical";
    defaultRules = {
      create = true;
      rules = {
        etcd = false; # disabled for now
        kubeApiserver = false; # https://github.com/prometheus-community/helm-charts/issues/1283
      };
    };

    global = {
      rbac = {
        create = true;
      };
    };
    alertmanager = {
      enabled = true;
      alertmanagerSpec =
        {
          priorityClassName = "system-cluster-critical";
          replicas = cfg.alertmanager_replicas;
        }
        // lib.optionalAttrs cfg.allow_external_rules {
          ConfigMatcherStrategy = {
            type = "None";
          };
        };
      serviceMonitor = {
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
        ];
      };
      inherit affinity tolerations;
    };

    kubeApiServer = {
      enabled = true;
      serviceMonitor = {
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_namespace"
              "__meta_kubernetes_service_name"
              "__meta_kubernetes_endpoint_port_name"
            ];
            action = "keep";
            regex = "default;kubernetes;https";
          }
          {
            targetLabel = "__address__";
            replacement = "kubernetes.default.svc:443";
          }
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
        ];
      };
    };
    kubelet = {
      enabled = true;
      serviceMonitor = {
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
          {
            sourceLabels = [
              "__metrics_path__"
            ];
            targetLabel = "metrics_path";
            action = "replace";
          }
        ];
      };
    };
    kubeControllerManager = {
      enabled = true;
      service = {
        port = 10257;
        targetPort = 10257;
      };
      serviceMonitor = {
        enabled = true;
        https = true;
        insecureSkipVerify = true;
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
        ];
      };
    };
    coreDNS = {
      enabled = true;
      serviceMonitor = {
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
        ];
      };
    };
    kubeEtcd = {
      enabled = true;
      service = {
        enabled = true;
        port = 2381;
        targetPort = 12381;
        selector = {
          "app.kubernetes.io/name" = "etcd-proxy-metrics";
        };
      };
      serviceMonitor = {
        enabled = true;
        scheme = "https";
        insecureSkipVerify = false;
        caFile = "/etc/prometheus/secrets/etcd-metrics-proxy/server.crt";
        certFile = "/etc/prometheus/secrets/etcd-metrics-proxy/client.crt";
        keyFile = "/etc/prometheus/secrets/etcd-metrics-proxy/client.key";
      };
    };
    kubeScheduler = {
      enabled = true;
      service = {
        enabled = true;
        port = 10259;
        targetPort = 10259;
      };
      serviceMonitor = {
        enabled = true;
        https = true;
        insecureSkipVerify = true;
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
        ];
      };
    };
    kubeProxy = {
      enabled = builtins.elem config.yk8s.kubernetes.network.plugin ["calico"];
      serviceMonitor = {
        enabled = true;
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
        ];
      };
    };
    kubeStateMetrics = {
      enabled = true;
      serviceMonitor = {
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
        ];
      };
    };
    kube-state-metrics = {
      priorityClassName = "system-cluster-critical";
      rbac = {
        create = true;
        pspEnabled = false;
      };
      customLabels = cfg.common_labels;
      metricLabelsAllowlist = [
        "namespaces=[*]"
      ];
    };
    nodeExporter = {
      enabled = true;
      ## Use the value configured in prometheus-node-exporter.podLabels
      jobLabel = "jobLabel";
    };
    ## Configuration for prometheus-node-exporter subchart
    ##
    prometheus-node-exporter = {
      priorityClassName = "system-node-critical";
      namespaceOverride = "";
      podLabels = {
        ## Add the 'node-exporter' label to be used by serviceMonitor to match standard common usage in rules and grafana dashboards
        jobLabel = "node-exporter";
      };
      extraArgs = [
        "--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)"
        "--collector.filesystem.ignored-fs-types=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
      ];
      prometheus = {
        monitor = {
          enabled = true;
          additionalLabels = cfg.common_labels;
          relabelings = [
            {
              sourceLabels = [
                "__meta_kubernetes_pod_node_name"
              ];
              separator = ";";
              regex = "^(.*)$";
              targetLabel = "nodename";
              replacement = "$1";
              action = "replace";
            }
          ];
        };
      };
    };
    prometheusOperator = {
      enabled = true;
      priorityClassName = "system-cluster-critical";
      admissionWebhooks = {
        patch = {
          priorityClassName = "system-cluster-critical";
        };
      };
      resources = cfg.prometheus_resources;
      serviceMonitor = {
        relabelings = [
          {
            sourceLabels = [
              "__meta_kubernetes_pod_node_name"
            ];
            separator = ";";
            regex = "^(.*)$";
            targetLabel = "nodename";
            replacement = "$1";
            action = "replace";
          }
        ];
      };
      inherit affinity tolerations;
    };
  };
}
