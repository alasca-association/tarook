{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  inherit (yk8s-lib.k8s) mkAffinity mkTolerations;
in {
  imports = [
    ./grafana.nix
    ./prometheus.nix
  ];
  config.yk8s.k8s-service-layer.prometheus.helm.values = let
    affinity = mkAffinity {inherit (cfg) scheduling_key;};
    tolerations = mkTolerations {inherit (cfg) scheduling_key;};
  in {
    commonLabels = cfg.common_labels;
    priorityClassName = "system-cluster-critical";
    ## Since 68.4.0 it is possible to use crds.upgradeJob.enabled for upgrading the CRDs
    ## The CRD upgrade job mitigates the limitation of helm not being able to upgrade CRDs.
    ## The job will apply the CRDs to the cluster before the operator is deployed, using helm hooks.
    ## It deploy a corresponding clusterrole, clusterrolebinding and serviceaccount to apply the CRDs.
    crds.upgradeJob = {
      inherit affinity tolerations;
      enabled = true;
      forceConflicts = true;
    };
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
          inherit affinity tolerations;
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
    };

    kubeApiServer = {
      enabled = true;
      admissionWebhooks.patch = {
        inherit affinity tolerations;
      };
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
      inherit affinity tolerations;
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
        ipDualStack = let
          inherit (config.yk8s.infra) ipv4_enabled ipv6_enabled;
        in {
          enabled = ipv4_enabled && ipv6_enabled;
          ipFamilies =
            (lib.optional ipv4_enabled "IPv4")
            ++ (lib.optional ipv6_enabled "IPv6");
          ipFamilyPolicy =
            if ipv4_enabled && ipv6_enabled
            then "PreferDualStack"
            else "SingleStack";
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
      enabled = config.yk8s.kubernetes.network.kube_proxy.enabled;
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
      inherit affinity tolerations;
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
            {
              sourceLabels = [
                "__meta_kubernetes_node_labelpresent_node_role_kubernetes_io_control_plane"
              ];
              targetLabel = "role";
              regex = "^true$";
              replacement = "control-plane";
            }
            {
              sourceLabels = [
                "__meta_kubernetes_node_labelpresent_node_role_kubernetes_io_worker"
              ];
              targetLabel = "role";
              regex = "^true$";
              replacement = "worker";
            }
          ];
          attachMetadata.node = true;
        };
      };
    };
    prometheusOperator = {
      enabled = true;
      inherit affinity tolerations;
      priorityClassName = "system-cluster-critical";
      admissionWebhooks.patch = {
        inherit affinity tolerations;
        priorityClassName = "system-cluster-critical";
      };
      resources = cfg.operator_resources;
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
  };
}
