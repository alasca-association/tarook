{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  modules-lib = import ../../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedResourceOptionModule mkMultiResourceOptionsModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) types;
in {
  imports = [
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "grafana_plugins"] "")

    (mkMultiResourceOptionsModule ["k8s-service-layer" "prometheus"] {
      description = ''
        GRAFANA POD RESOURCE LIMITS
        The following limits are applied to the respective pods.
        Note that the Prometheus limits are chosen fairly conservatively and may need
        tuning for larger and smaller clusters.
        By default, we prefer to set limits in such a way that the Pods end up in the
        Guaranteed QoS class (i.e. both CPU and Memory limits and requests set to the
        same value).
      '';
      resources = {
        grafana.memory.limit = "512Mi";
        grafana.cpu.request = "100m";
        grafana.cpu.example = "500m";
      };
    })
    (mkRenamedResourceOptionModule ["k8s-service-layer" "prometheus"] [
      "grafana"
    ])
  ];

  options.yk8s.k8s-service-layer.prometheus = {
    grafana_admin_secret_name = mkOption {
      type = types.yk8s.k8s.secretName;
      default = "cah-grafana-admin";
    };

    grafana_dashboard_enable_multicluster_support = mkEnableOption ''
      referencing multiple K8s clusters by a single Grafana datasource.
    '';

    use_grafana = mkOption {
      description = "Enable grafana";
      type = types.bool;
      default = true;
    };

    grafana_root_url = mkOption {
      description = ''
        The full public facing url you use in browser, used for redirects and emails
      '';
      type = with types; nullOr yk8s.networking.httpxHostPathUrl;
      default = null;
    };

    grafana_persistent_storage_class = mkOption {
      description = ''
        If this variable is defined, Grafana will store its data in a PersistentVolume
        in the defined StorageClass. Otherwise, persistence is disabled for Grafana.
        The value has to be a valid StorageClass available in your cluster.
      '';
      type = with types; nullOr yk8s.k8s.storageClassName;
      default = null;
    };
  };
}
