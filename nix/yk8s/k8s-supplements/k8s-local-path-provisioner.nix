{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.local_storage.dynamic;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkSubSection;
in {
  options.yk8s.kubernetes.local_storage.dynamic = mkSubSection {
    _docs.order = 7;

    enabled = mkEnableOption ''
      dynamic local storage provisioning. This provides a storage class which
      can be used with PVCs to allocate local storage on a node.
    '';
    storageclass_name = mkOption {
      description = ''
        Name of the storage class to create.

        NOTE: the static and dynamic provisioner must have distinct storage class
        names if both are enabled!
      '';
      type = types.nonEmptyStr;
      default = "local-storage";
      apply = with config.yk8s.kubernetes.local_storage;
        v:
          if
            static.enabled
            && dynamic.enabled
            && static.storageclass_name == v
          then
            throw
            "[local_storage] Static and dynamic storage classes must have different names"
          else v;
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the components in
      '';
      type = types.nonEmptyStr;
      default = "kube-system";
    };
    data_directory = mkOption {
      description = ''
        Directory where the volumes will be placed on the worker node
      '';
      type = types.nonEmptyStr;
      default = "/mnt/dynamic-data";
    };
    version = mkOption {
      description = ''
        Version of the local path controller to deploy
      '';
      type = types.str;
      default = "v0.0.20"; # TODO either ensure leading "v" or add it?
    };

    nodeplugin_toleration = mkOption {
      description = ''
        nodeplugin toleration.
        Setting this to true will cause the dynamic storage plugin
        to run on all nodes (ignoring all taints). This is often desirable.
      '';
      type = types.bool;
      default = config.yk8s.kubernetes.storage.nodeplugin_toleration;
      defaultText = "\${config.yk8s.kubernetes.storage.nodeplugin_toleration}";
    };
  };
}
