{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  inherit (lib) mkOption mkEnableOption types;
in {
  options.yk8s.kubernetes = {
    storage = {
      rook_enabled = mkEnableOption ''
        Many clusters will want to use rook, so you should enable
        or disable it here if you want. It requires extra options
        which need to be chosen with care.
      '';
      nodeplugin_toleration = mkEnableOption ''
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
        default = true;
      };
    };
    local_storage = {
      static = {
        enabled = mkEnableOption ''
          Enable static provisioning of local storage. This provisions a single local
          storage volume per worker node.

          It is recommended to use the dynamic local storage instead.
        '';
        storageclass_name = mkOption {
          description = ''
            Name of the storage class to create.

            NOTE: the static and dynamic provisioner must have distinct storage class
            names if both are enabled!
          '';
          type = types.str;
          default = "local-storage";
        };
      };
      dynamic = {
        enabled = mkEnableOption ''
          Enable dynamic local storage provisioning. This provides a storage class which
          can be used with PVCs to allocate local storage on a node.
        '';
        storageclass_name = mkOption {
          description = ''
            Name of the storage class to create.

            NOTE: the static and dynamic provisioner must have distinct storage class
            names if both are enabled!
          '';
          type = types.str;
          default = "local-storage";
        };
        namespace = mkOption {
          description = ''
            Namespace to deploy the components in
          '';
          type = types.str;
          default = "kube-system";
        };
        data_directory = mkOption {
          description = ''
            Directory where the volumes will be placed on the worker node
          '';
          type = types.str;
          default = "/mnt/dynamic-data";
        };
        version = mkOption {
          description = ''
            Version of the local path controller to deploy
          '';
          type = types.str;
          default = "v0.0.20"; # TODO either ensure leading "v" or add it
        };

        # nodeplugin_toleration = # TODO toleration submodule
      };
      # TODO ensure storage class names are distinct
    };
  };
}
