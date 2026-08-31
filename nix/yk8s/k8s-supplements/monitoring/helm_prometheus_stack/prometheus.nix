{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  inherit (yk8s-lib.k8s) mkAffinity mkTolerations;
  affinity = mkAffinity {inherit (cfg) scheduling_key;};
  tolerations = mkTolerations {inherit (cfg) scheduling_key;};
in {
  config.yk8s.k8s-service-layer.prometheus.helm.values = {
    prometheus = {
      enabled = true;
      thanosService = {
        enabled = cfg.use_thanos;
      };
      thanosServiceMonitor = {
        enabled = cfg.use_thanos;
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
      prometheusSpec =
        {
          priorityClassName = "system-cluster-critical";
          remoteWrite =
            map (
              remote_write:
                {
                  url = remote_write.url;
                  writeRelabelConfigs = remote_write.write_relabel_configs;
                }
                // lib.optionalAttrs (remote_write.basic_auth_secret_name != null) {
                  basicAuth = {
                    username = {
                      name = remote_write.basic_auth_secret_name;
                      key = "username";
                    };
                    password = {
                      name = remote_write.basic_auth_secret_name;
                      key = "password";
                    };
                  };
                }
            )
            cfg.remote_writes;
          secrets = [
            "etcd-metrics-proxy"
          ];
          serviceMonitorSelectorNilUsesHelmValues = cfg.common_labels != {};

          containers = [
            {
              name = "prometheus";
              readinessProbe = {
                failureThreshold = 1000;
              };
            }
          ];
          resources = cfg.prometheus_resources;
          inherit affinity tolerations;
        }
        // lib.optionalAttrs (cfg.prometheus_persistent_storage_class != null) {
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = cfg.prometheus_persistent_storage_class;
                accessModes = [
                  "ReadWriteOnce"
                ];
                resources = {
                  requests = {
                    storage = cfg.prometheus_persistent_storage_resource_request;
                  };
                };
              };
            };
          };
        }
        // lib.optionalAttrs (cfg.common_labels != {}) {
          serviceMonitorSelector = {
            matchLabels = cfg.common_labels;
          };
        }
        // lib.optionalAttrs (cfg.use_thanos) {
          thanos = {
            objectStorageConfig =
              {
                optional = false;
              }
              // (
                let
                  existingSecret = {
                    name = "thanos-sidecar-bucket-credentials-config";
                    key = "thanos.yaml";
                  };
                in
                  if (lib.toInt (lib.versions.major cfg.helm.chart_version)) >= 51
                  then {inherit existingSecret;}
                  else {inherit (existingSecret) name key;}
              );
          };
        }
        // lib.optionalAttrs cfg.allow_external_rules {
          ruleSelectorNilUsesHelmValues = false;
          ruleSelector = {};
          ruleNamespaceSelector = {};
        };
    };
  };
}
