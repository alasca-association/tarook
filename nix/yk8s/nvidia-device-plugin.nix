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
  options.yk8s.nvidia-device-plugin = mkTopSection {
      device_plugin_namespace = mkOption {
        type = types.nonEmptyStr;
        description = ''
          Namespace into which the NVIDIA device plugin will get deployed.
          Note that the NVIDIA device plugin is only installed
          if at least one GPU node is detected and uninstalled
          otherwise!
        '';
        default = "k8s-nvidia-device-plugin";
      };
      device_plugin_chart_ref = mkOption {
        type = types.nonEmptyStr;
        description = ''
          Helm chart reference for the NVIDIA device plugin.
          Note that the NVIDIA device plugin is only installed
          if at least one GPU node is detected and uninstalled
          otherwise!
        '';
        default = "nvdp/nvidia-device-plugin";
      };
      device_plugin_helm_repo_url = mkOption {
        type = types.str;
        description = ''
          Helm repository URL for the NVIDIA device plugin.
          Note that the NVIDIA device plugin is only installed
          if at least one GPU node is detected and uninstalled
          otherwise!
        '';
        default = "https://nvidia.github.io/k8s-device-plugin";
      };
      device_plugin_chart_version = mkOption {
        type = types.str;
        description = ''
          Helm chart version for the NVIDIA device plugin.
          Note that the NVIDIA device plugin is only installed
          if at least one GPU node is detected and uninstalled
          otherwise!
        '';
        # renovate: datasource=helm depName=nvidia-device-plugin registryUrl=https://nvidia.github.io/k8s-device-plugin
        default = "0.17.0";
      };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "nvidia_";
      inventory_path = "all/nvidia-device-plugin.yaml";
      transformations = [
        (cfg:
          if config.yk8s.kubernetes.is_gpu_cluster
          then cfg
          else {})
      ];
    })
  ];
}