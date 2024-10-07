{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  inherit (yk8s-lib) mkAffinity mkTolerations;
in {
  config.yk8s.k8s-service-layer.prometheus.prometheus_stack_default_values = {
    prometheus = {
      enabled = true;
      thanosService = {
        enabled = "{{ monitoring_use_thanos | bool }}";
      };
      thanosServiceMonitor = {
        enabled = "{{ monitoring_use_thanos | bool }}";
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
          remoteWrite = cfg.remote_writes;
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
          resources = "cfg.prometheus_resources";
          affinity = mkAffinity {inherit (cfg) scheduling_key;};
          tolerations = mkTolerations cfg.scheduling_key;
        }
        // lib.optionalAttrs (cfg.prometheus_persistent_storage_class != null) {
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = cfg.prometheus_persistent_storage_class != null;
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
                  if (lib.toInt (lib.versions.major cfg.prometheus_stack_version)) >= 51
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
