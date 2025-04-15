{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.storage;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkSubSection;
  inherit (yk8s-lib.options) mkHelmValuesOption;
in {
  options.yk8s.kubernetes.storage = mkSubSection {
    _docs.order = 5;
    rook_enabled = mkEnableOption ''
      Rook.
      Many clusters will want to use rook, so you should enable
      or disable it here if you want. It requires extra options
      which need to be chosen with care.
    '';
    nodeplugin_toleration = mkEnableOption ''
      nodeplugin toleration.
      Setting this to true will cause the storage plugins
      to run on all nodes (ignoring all taints). This is often desirable.
    '';

    cinder_enable_topology = mkOption {
      description = ''
        This flag enables the topology feature gate of the cinder controller plugin.
        Its purpose is to allocate volumes from cinder which are in the same AZ as
        the worker node to which the volume should be attached.
        Important: Cinder must support AZs and the AZs must match the AZs used by nova!
      '';
      type = types.bool;
      default = false;
      example = true;
    };

    helm_values = mkHelmValuesOption {
      name = "cinder-csi";
      valuesDocUrl = "https://artifacthub.io/packages/helm/cloud-provider-openstack/openstack-cinder-csi";
    };
  };

  config.yk8s.kubernetes.storage.cinder.helm_values = {
    storageClass = {
      enabled = false;
    };
    secret = {
      enabled = true;
      create = false;
      name = "cloud-config";
    };
    csi = {
      provisioner = {
        topology =
          if cfg.cinder_enable_topology
          then "true"
          else "false";
      };
      plugin = {
        nodePlugin = {
          dnsPolicy = "ClusterFirst";
          priorityClassName = "system-node-critical";
        };
      };
    };
  };
}
