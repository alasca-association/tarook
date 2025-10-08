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
  inherit (yk8s-lib.options) mkHelmChartVersionOption;
  inherit (yk8s-lib) types;
in {
  imports = [
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "use_helm_thanos"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_metadata_volume_size"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_metadata_volume_storage_class"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "prometheus" "thanos_objectstorage_config_path"] "Use `thanos_objectstorage_config_file` instead.")

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

        thanos_store.memory.limit = "2Gi";
        thanos_store.cpu.request = "100m";
        thanos_store.cpu.example = "500m";
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

    thanos_chart_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=thanos registryUrl=https://charts.bitnami.com/bitnami
      default = "17.2.3";
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
    thanos_store_in_memory_max_size = mkOption {
      description = ''
        https://thanos.io/tip/components/store.md/#in-memory-index-cache
        Note: Unit must be specified as decimal! (MB,GB)
        This value should be chosen in a sane matter based on
        thanos_store_memory_request and thanos_store_memory_limit
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
  };
}
