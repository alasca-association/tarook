{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.nvidia;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
  inherit (modules-lib) mkHelmValuesModule;
in {
  imports = [(mkHelmValuesModule "nvidia" "device_plugin")];
  options.yk8s.nvidia = mkTopSection {
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

  config.yk8s.nvidia.device_plugin_default_values = {
    nodeSelector = {
      "k8s.yaook.cloud/gpu-node" = "true";
    };
    tolerations = [
      {
        key = "";
        operator = "Exists";
      }
    ];

    # Subcharts
    # https://github.com/NVIDIA/gpu-operator/tree/master/deployments/gpu-operator/charts/node-feature-discovery
    nfd = {
      worker = {
        tolerations = [
          {
            key = "";
            operator = "Exists";
          }
        ];
        nodeSelector = {
          "k8s.yaook.cloud/gpu-node" = "true";
        };
      };
    };

    # https://github.com/NVIDIA/gpu-feature-discovery
    gfd = {
      enabled = true;
    };
  };

  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "nvidia_";
      inventory_path = "all/nvidia.yaml";
      transformations = [
        (c:
          if config.yk8s.kubernetes.virtualize_gpu
          then c
          else {})
      ];
    })
  ];
}
