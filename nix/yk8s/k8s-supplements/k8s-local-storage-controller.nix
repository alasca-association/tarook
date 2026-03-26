{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.local_storage.static;
  inherit (lib) mkOption mkEnableOption;
  inherit (yk8s-lib) mkSubSection types;
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
      type = types.yk8s.k8s.storageClassName;
      default = "local-storage";
    };
    namespace = mkOption {
      type = types.yk8s.k8s.namespaceName;
      default = "kube-system";
    };
    discovery_directory = mkOption {
      type = types.yk8s.posix.absolutePath;
      default = "/mnt/mk8s-disks";
    };
    data_directory = mkOption {
      type = types.yk8s.posix.absolutePath;
      default = "/mnt/data";
    };
    version = mkOption {
      description = ''
        See https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/releases/tag/v2.5.0
      '';
      type = types.yk8s.oci.imageTag;
      default = "v2.5.0";
    };
    nodeplugin_toleration = mkOption {
      type = types.bool;
      default = config.yk8s.kubernetes.storage.nodeplugin_toleration;
    };
  };

  config.yk8s.warnings = lib.optional (cfg.enabled) "config.yk8s.kubernetes.local_storage.static is deprecated. Support for it will be dropped in a release after v13.0.0";
  config.yk8s._targets.ansible.assertions = [
    {
      assertion = cfg.enabled && config.yk8s.kubernetes.local_storage.dynamic.enabled -> cfg.storageclass_name != config.yk8s.kubernetes.local_storage.dynamic.storageclass_name;
      message = ''
        If config.yk8s.kubernetes.local_storage.static.enabled
          and config.yk8s.kubernetes.local_storage.dynamic.enabled are both true,
          config.yk8s.kubernetes.local_storage.static.storageclass_name and
          config.yk8s.kubernetes.local_storage.dynamic.storageclass_name must differ.
      '';
    }
  ];
  config.yk8s._targets.ansible.warnings = [];
}
