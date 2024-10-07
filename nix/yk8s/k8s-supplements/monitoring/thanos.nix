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
  inherit (yk8s-lib) mkAffinity mkTolerations;
  inherit (yk8s-lib.types) k8sSize;
in {
  imports =
    [
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "thanos_metadata_volume_size" "")
      (mkRemovedOptionModule "k8s-service-layer.prometheus" "thanos_metadata_volume_storage_class" "")

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
      (mkHelmValuesModule "k8s-service-layer.prometheus" "thanos")
    ]
    ++ (mkRenamedResourceOptionModules "k8s-service-layer.prometheus" [
      "thanos_sidecar"
      "thanos_query"
      "thanos_compact"
      "thanos_store"
    ]);
  options.yk8s.k8s-service-layer.prometheus = {
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

    thanos_config_secret_name = mkOption {
      type = types.str;
      default = "thanos-bucket-config";
    };

    thanos_retention_resolution_raw = mkOption {
      type = types.str;
      default = "30d";
    };
    thanos_retention_resolution_5m = mkOption {
      type = types.str;
      default = "60d";
    };
    thanos_retention_resolution_1h = mkOption {
      type = types.str;
      default = "180d";
    };

    thanos_store_in_memory_max_size = mkOption {
      description = ''
        https://thanos.io/tip/components/store.md/#in-memory-index-cache
        Note: Unit must be specified as decimal! (MB,GB)
        This value should be chosen in a sane matter based on
        thanos_store_memory_request and thanos_store_memory_limit
      '';
      type = with types; nullOr (strMatching "([0-9]+[MG]B)");
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
    thanos_query_additional_store_endpoints = mkOption {
      description = ''
        Provide a list of DNS endpoints for additional thanos store endpoints.
        The endpoint will be extended to `dnssrv+_grpc._tcp.{{ endpoint }}.monitoring.svc.cluster.local`.
      '';
      type = with types; listOf nonEmptyStr;
      default = [];
    };
  };

  config.yk8s.k8s-service-layer.prometheus.thanos_default_values = let
    affinity = mkAffinity {inherit (cfg) scheduling_key;};
    tolerations = mkTolerations cfg.scheduling_key;
  in {
    global = lib.optionalAttrs (cfg.thanos_storage_class != null) {
      storageClass = cfg.thanos_storage_class;
    };
    existingObjstoreSecret = cfg.thanos_config_secret_name;
    compactor = {
      enabled = true;
      retentionResolutionRaw = cfg.thanos_retention_resolution_raw;
      retentionResolution5m = cfg.thanos_retention_resolution_5m;
      retentionResolution1h = cfg.thanos_retention_resolution_1h;
      resources = cfg.thanos_compact_resources;
      inherit affinity tolerations;
      persistence =
        {
          enabled = cfg.thanos_storage_class != null;
        }
        // lib.optionalAttrs (cfg.thanos_compactor_size != null) {
          size = cfg.thanos_compactor_size;
        };
    };

    storegateway =
      {
        enabled = true;
        extraFlags =
          lib.optional (cfg.thanos_store_in_memory_max_size != null)
          "--index-cache-size=${cfg.thanos_store_in_memory_max_size}";
        resources = cfg.thanos_store_resources;
        inherit affinity tolerations;
        persistence.enabled = cfg.thanos_storage_class != null;
      }
      // lib.optionalAttrs (cfg.thanos_storegateway_size != null) {
        size = cfg.thanos_storegateway_size;
      };

    query = {
      enabled = true;
      resources = cfg.thanos_query_resources;
      dnsDiscovery = {
        enabled = true;
        sidecarsService = "prometheus-operated";
        sidecarsNamespace = cfg.namespace;
      };
      inherit affinity tolerations;
      extraFlags = [
        "--query.auto-downsampling"
        "--query.timeout=1m"
      ];
    };
    queryFrontend = {
      enabled = false;
    };

    metrics = {
      enabled = true;
      serviceMonitor = {
        enabled = true;
        labels = cfg.common_labels;
      };
    };
  };
}
