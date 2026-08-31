{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.prometheus;
  modules-lib = import ../../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedResourceOptionModule mkMultiResourceOptionsModule mkRenamedOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
  inherit (yk8s-lib.k8s) mkAffinity mkTolerations;
  inherit (yk8s-lib) types;
in {
  imports = [
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "use_helm_thanos"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_metadata_volume_size"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_metadata_volume_storage_class"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_objectstorage_config_path"] "Use `thanos_objectstorage_config_file` instead.")

    (mkRenamedOptionModule ["k8s-service-layer" "prometheus" "thanos_chart_version"] ["k8s-service-layer" "prometheus" "thanos" "helm" "chart_version"])

    (mkRenamedOptionModule ["k8s-service-layer" "prometheus" "thanos_store_resources"] ["k8s-service-layer" "prometheus" "thanos_storegateway_resources"])
    (mkRenamedOptionModule ["k8s-service-layer" "prometheus" "thanos_store_in_memory_max_size"] ["k8s-service-layer" "prometheus" "thanos_storegateway_in_memory_max_size"])

    (mkMultiResourceOptionsModule ["k8s-service-layer" "prometheus"] {
      description = ''
        THANOS POD RESOURCE LIMITS
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

        thanos_storegateway.memory.limit = "2Gi";
        thanos_storegateway.cpu.request = "100m";
        thanos_storegateway.cpu.example = "500m";
      };
    })
    (mkRenamedResourceOptionModule ["k8s-service-layer" "prometheus"] [
      "thanos_sidecar"
      "thanos_query"
      "thanos_compact"
      "thanos_store"
    ])
  ];

  options.yk8s.k8s-service-layer.prometheus = {
    use_thanos = mkEnableOption "use of Thanos";

    manage_thanos_bucket = mkOption {
      description = ''
        Let terraform create an object storage container / bucket for you if `true`.
        If set to `false` one must provide a valid configuration via Vault.
        See :ref:`thanos.custom-bucket-management` for details.
      '';
      type = types.bool;
      default = true;
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
      type = with types; nullOr yk8s.k8s.storageClassName;
      default = null;
    };

    thanos_storegateway_size = mkOption {
      description = ''
        You can explicitly set the PV size for each component.
        If left undefined, the helm chart defaults will be used

        Immutable when deployed. (See also :ref:`cluster-configuration.prometheus-configuration.updating-immutable-options`)
      '';
      type = with types; nullOr yk8s.k8s.quantity;
      default = null;
    };

    thanos_compactor_size = mkOption {
      description = ''
        You can explicitly set the PV size for each component.
        If left undefined, the helm chart defaults will be used

        Immutable when deployed. (See also :ref:`cluster-configuration.prometheus-configuration.updating-immutable-options`)
      '';
      type = with types; nullOr yk8s.k8s.quantity;
      default = null;
    };
    thanos_storegateway_in_memory_max_size = mkOption {
      description = ''
        https://thanos.io/tip/components/store.md/#in-memory-index-cache
        Note: Unit must be specified as decimal! (MB,GB)
        This value should be chosen in a sane matter based on
        thanos_storegateway_resources.requests.memory and thanos_storegateway_resources.limits.memory
      '';
      type = with types; nullOr yk8s.units.bytesPower10;
      default = null;
    };
    thanos_objectstorage_container_name = mkOption {
      type = types.yk8s.openstack.swiftContainerName;
      default = "${config.yk8s.infra.cluster_name}-monitoring-thanos-data";
      defaultText = "\${config.yk8s.infra.cluster_name}-monitoring-thanos-data";
    };
    thanos_objectstorage_config_file = mkOption {
      description = ''
        Note: The given path is interpreted as being relative to the cluster repo's config directory.
      '';
      # NOTE: Not using `pathInStore` here because the expected file contains secrets
      # TODO: Eliminate config option and store secrets solely in Vault
      type = with types; nullOr yk8s.posix.relativePath;
      default = null;
      example = "./monitoring/thanos_objectstorage.config";
    };
    thanos_query_additional_store_endpoints = mkOption {
      description = ''
        Provide a list of DNS endpoints for additional thanos store endpoints.
        The endpoint will be extended to `dnssrv+_grpc._tcp.{{ endpoint }}.monitoring.svc.cluster.local`.
      '';
      type = with types; listOf yk8s.networking.subdomainLabel;
      default = [];
    };
    thanos_retention_resolution_raw = mkOption {
      description = ''
        Configure the retention policy for raw (non-downsampled) blocks in the
        object store.
        Keep in mind that the initial goal of downsampling is not saving disk or
        object storage space. In fact, downsampling doesn’t save you any space but
        instead, it adds 2 more blocks for each raw block which are only slightly
        smaller or relatively similar size to raw blocks.
      '';
      type = types.str;
      default = "30d";
    };
    thanos_retention_resolution_5m = mkOption {
      description = ''
        Configure the retention policy for blocks downsampled at 5 minute resolution
        in the object store.
        Keep in mind that the initial goal of downsampling is not saving disk or
        object storage space. In fact, downsampling doesn’t save you any space but
        instead, it adds 2 more blocks for each raw block which are only slightly
        smaller or relatively similar size to raw blocks.
      '';
      type = types.str;
      default = "60d";
    };
    thanos_retention_resolution_1h = mkOption {
      description = ''
        Configure the retention policy for blocks downsampled at 1 hour resolution
        in the object store.
        Keep in mind that the initial goal of downsampling is not saving disk or
        object storage space. In fact, downsampling doesn’t save you any space but
        instead, it adds 2 more blocks for each raw block which are only slightly
        smaller or relatively similar size to raw blocks.
      '';
      type = types.str;
      default = "180d";
    };
    thanos_config_secret_name = mkOption {
      description = ''
        Configure an external object store Secret.
      '';
      type = types.str;
      default = "thanos-bucket-config";
    };
    thanos.helm = mkHelmReleaseOptions {
      descriptionName = "Bitnami Thanos";
      defaultChartRef = "oci://registry-1.docker.io/bitnamicharts/thanos";
      # renovate: datasource=docker depName=registry-1.docker.io/bitnamicharts/thanos
      defaultChartVersion = "17.2.6";
      defaultReleaseNamespace = "monitoring";
      defaultReleaseName = "thanos";
      valuesDocUrl = "https://github.com/bitnami/charts/blob/main/bitnami/thanos/values.yaml";
      chartOptions = {};
    };
  };

  config.yk8s.k8s-service-layer.prometheus.thanos.helm.values = let
    affinity = mkAffinity {inherit (cfg) scheduling_key;};
    tolerations = mkTolerations {inherit (cfg) scheduling_key;};
  in {
    global =
      {
        # Original containers have been substituted, see https://github.com/bitnami/containers/issues/83267
        security.allowInsecureImages = true;
      }
      // (lib.optionalAttrs (cfg.thanos_storage_class != null) {
        storageClass = cfg.thanos_storage_class;
      });
    image.repository = "bitnamilegacy/thanos";
    existingObjstoreSecret = cfg.thanos_config_secret_name;
    compactor = {
      enabled = true;
      extraFlags = [
        "--no-debug.halt-on-error" # must exit for Kubernetes to restart it
      ];
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

    storegateway = {
      enabled = true;
      extraFlags =
        lib.optional (cfg.thanos_storegateway_in_memory_max_size != null)
        "--index-cache-size=${cfg.thanos_storegateway_in_memory_max_size}";
      resources = cfg.thanos_storegateway_resources;
      inherit affinity tolerations;
      pdb.create = false;
      replicaCount = 1;
      persistence =
        {
          enabled = cfg.thanos_storage_class != null;
        }
        // lib.optionalAttrs (cfg.thanos_storegateway_size != null) {
          size = cfg.thanos_storegateway_size;
        };
    };

    query = {
      enabled = true;
      resources = cfg.thanos_query_resources;
      dnsDiscovery = {
        enabled = true;
        sidecarsService = "prometheus-operated";
        sidecarsNamespace = cfg.thanos.helm.release_namespace;
      };
      inherit affinity tolerations;
      pdb.create = false;
      replicaCount = 1;
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
