{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.nvidia;
  inherit (lib) mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.nvidia = mkTopSection {
    vgpu = {
      driver_blob_url = mkOption {
        description = ''
          Should point to a object store or otherwise web server, where the vGPU Manager installation file is available.
        '';
        type = types.str;
      };
      manager_filename = mkOption {
        description = ''
          Should hold the name of the vGPU Manager installation file.
        '';
        type = types.str;
      };
    };
    config.yk8s.nvidia = {
      _ansible_prefix = "nvidia_";
      _inventory_path = "all/nvidia.yaml";
      _variable_transformation = vars:
        if config.yk8s.virtualize_gpu
        then vars
        else {};
    };
  };
}
