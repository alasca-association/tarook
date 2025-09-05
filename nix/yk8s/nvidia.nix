{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.nvidia;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
in {
  options.yk8s.nvidia = mkTopSection {
    vgpu = {
      driver_blob_url = mkOption {
        description = ''
          Should point to a object store or otherwise web server, where the vGPU Manager installation file is available.
        '';
        type = types.either types.yk8s.networking.httpxUrl types.yk8s.networking.xftpUrl;
      };
      manager_filename = mkOption {
        description = ''
          Should hold the name of the vGPU Manager installation file.
        '';
        type = types.yk8s.posix.filename;
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
