{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.local_storage.static;
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
  options.yk8s.kubernetes.local_storage.static = mkSubSection {
    _docs.order = 6;
    enabled = mkEnableOption ''
      static provisioning of local storage. This provisions a single local
      storage volume per worker node.

      It is recommended to use the dynamic local storage instead.
    '';
    storageclass_name = mkOption {
      description = ''
        Name of the storage class to create.

        NOTE: the static and dynamic provisioner must have distinct storage class
        names if both are enabled!
      '';
      type = k8sStorageClassName;
      default = "local-storage";
    };
    namespace = mkOption {
      type = k8sNamespaceName;
      default = "kube-system";
    };
    discovery_directory = mkOption {
      type = absolutePosixPath;
      default = "/mnt/mk8s-disks";
    };
    data_directory = mkOption {
      type = absolutePosixPath;
      default = "/mnt/data";
    };
    version = mkOption {
      description = ''
        See https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/releases/tag/v2.5.0
      '';
      type = ociImageTag;
      default = "v2.5.0";
    };
    nodeplugin_toleration = mkOption {
      type = types.bool;
      default = config.yk8s.kubernetes.storage.nodeplugin_toleration;
    };
  };
}
