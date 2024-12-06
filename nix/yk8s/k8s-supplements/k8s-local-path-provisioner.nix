{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.local_storage.dynamic;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkSubSection;
  inherit
    (yk8s-lib.types)
    absolutePosixPath
    k8sNamespaceName
    k8sStorageClassName
    ociImageTag
    ;
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
      type = k8sStorageClassName;
      default = "local-storage";
      apply = with config.yk8s.kubernetes.local_storage;
        v:
          if
            static.enabled
            && dynamic.enabled
            && static.storageclass_name == v
          then
            throw
            "config.yk8s.kubernetes.local_storage.dynamic.storageclass_name: must not match config.yk8s.kubernetes.local_storage.static.storageclass_name='${static.storageclass_name}'"
          else v;
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the components in
      '';
      type = k8sNamespaceName;
      default = "kube-system";
    };
    data_directory = mkOption {
      description = ''
        Directory where the volumes will be placed on the worker node
      '';
      type = absolutePosixPath;
      default = "/mnt/dynamic-data";
    };
    version = mkOption {
      description = ''
        Version of the local path controller to deploy
      '';
      type = ociImageTag;
      default = "v0.0.20";
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
