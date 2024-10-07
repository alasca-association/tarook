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
    grafana = {
      priorityClassName = "system-cluster-critical";
      enabled = cfg.use_grafana;
      persistence = {
        enabled = cfg.grafana_persistent_storage_class != null;
        storageClassName = cfg.grafana_persistent_storage_class;
      };
      admin = {
        existingSecret = cfg.grafana_admin_secret_name;
        userKey = "admin-user";
        passwordKey = "admin-password";
      };
      resources = cfg.grafana_resources;
      tolerations = mkTolerations cfg.scheduling_key;
      affinity =
        mkAffinity {
          inherit (cfg) scheduling_key;
        }
        // lib.optionalAttrs (cfg.grafana_persistent_storage_class != null) {
          pod_affinity_key = "app.kubernetes.io/name";
          pod_affinity_operator = "In";
          pod_affinity_values = ["grafana"];
        };
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1;
          datasources =
            lib.optional cfg.use_thanos
            {
              name = "thanos";
              type = "prometheus";
              access = "proxy";
              orgId = 1;
              url = "http://thanos-query.{{ monitoring_namespace }}.svc:9090";
              version = 1;
              editable = false;
            };
        };
      };
      sidecar = {
        dashboards = {
          enabled = true;
          label = "grafana_dashboard";
          searchNamespace = "ALL";
          folderAnnotation = "customer-dashboards";
          provider = {
            foldersFromFilesStructure = true;
          };
        };
      };
      serviceMonitor = {
        enabled = true;
        labels = cfg.common_labels;
        #     # https://github.com/prometheus-community/helm-charts/issues/1776
        interval = "30s";
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
      dashboards = {
        managed =
          {
            dashboard-calico = {
              gnetId = 12175;
              revision = 5;
              datasource = "Prometheus";
            };
          }
          // (lib.optionalAttrs config.yk8s.kubernetes.storage.rook_enabled {
            dashboard-ceph-cluster = {
              gnetId = 2842;
              revision = 14;
              datasource = "Prometheus";
            };
            dashboard-ceph-osd-single = {
              gnetId = 5336;
              revision = 5;
              datasource = "Prometheus";
            };
            dashboard-ceph-pools = {
              gnetId = 5342;
              revision = 5;
              datasource = "Prometheus";
            };
          })
          // (lib.optionalAttrs cfg.use_thanos {
            dashboard-thanos = {
              gnetId = 12937;
              revision = 4;
              datasource = "Prometheus";
            };
          })
          // (lib.optionalAttrs config.yk8s.k8s-service-layer.ingress.enabled {
            dashboard-nginx-ingress = {
              gnetId = 9614;
              revision = 1;
              datasource = "Prometheus";
            };
          });
      };

      dashboardProviders = {
        "managed-dashboard-provider.yaml" = {
          apiVersion = 1;
          providers = [
            {
              name = "managed-dashboards";
              folder = "managed-dashboards";
              options = {
                path = "/var/lib/grafana/dashboards/managed";
              };
            }
          ];
        };
      };
      "grafana.ini" = {
        server = lib.optionalAttrs (cfg.grafana_root_url != null) {
          root_url = cfg.grafana_root_url;
        };
      };
    };
  };
}
