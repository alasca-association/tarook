{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.nvidia;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  options.yk8s.nvidia = mkTopSection {
    _docs.preface = ''
      .. _cluster-configuration.nvidia-configuration:

      Nvidia (v)GPU Configuration
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^
    '';
    vgpu = {
      driver_blob_url = mkOption {
        description = ''
          Should point to a object store or otherwise web server, where the vGPU Manager installation file is available.
        '';
        type = types.nonEmptyStr;
      };
      manager_filename = mkOption {
        description = ''
          Should hold the name of the vGPU Manager installation file.
        '';
        type = types.nonEmptyStr;
      };
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "nvidia_";
      inventory_path = "all/nvidia.yaml";
      transformations = [
        (cfg:
          if config.yk8s.kubernetes.virtualize_gpu
          then cfg
          else {})
      ];
    })
  ];
}
