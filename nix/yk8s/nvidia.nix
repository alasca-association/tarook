{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.nvidia;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
  inherit (yk8s-lib.k8s) mkTolerations;
  inherit (lib) mkOption;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
in {
  options.yk8s.nvidia = mkTopSection {
    vgpu = {
      driver_blob_url = mkOption {
        description = ''
          Should point to a object store or otherwise web server, where the vGPU Manager installation file is available.
        '';
        type = with types; either yk8s.networking.httpxUrl yk8s.networking.xftpUrl;
      };
      manager_filename = mkOption {
        description = ''
          Should hold the name of the vGPU Manager installation file.
        '';
        type = types.yk8s.posix.filename;
      };
    };
    device_plugin = {
      install = mkOption {
        type = types.bool;
        default = config.yk8s.kubernetes.is_gpu_cluster && !config.yk8s.kubernetes.virtualize_gpu;
        visible = false;
        readOnly = true;
      };
      helm = mkHelmReleaseOptions {
        descriptionName = "nvidia device plugin";
        valuesDocUrl = "https://github.com/NVIDIA/k8s-device-plugin/blob/main/deployments/helm/nvidia-device-plugin/values.yaml";
        defaultRepoUrl = "https://nvidia.github.io/k8s-device-plugin";
        defaultChartRef = "nvidia-device-plugin";
        # renovate: datasource=helm depName=nvidia-device-plugin registryUrl=https://nvidia.github.io/k8s-device-plugin
        defaultChartVersion = "0.20.0";
        defaultReleaseNamespace = "k8s-nvidia-device-plugin";
        defaultReleaseName = "nvdp";
      };
    };
  };

  config.yk8s.nvidia.device_plugin.helm.values = let
    schedulingSettings = {
      nodeSelector = {"k8s.yaook.cloud/gpu-node" = "true";};
      tolerations = mkTolerations {scheduling_key = "";};
    };
  in
    schedulingSettings
    // {
      # Subcharts
      # https://github.com/NVIDIA/k8s-device-plugin/blob/3c378193fcebf6e955f0d65bd6f2aeed099ad8ea/deployments/helm/nvidia-device-plugin/Chart.yaml#L10
      # https://kubernetes-sigs.github.io/node-feature-discovery/master/deployment/helm.html
      nfd = {
        worker = schedulingSettings;
        gc.tolerations = schedulingSettings.tolerations;
      };

      # https://github.com/NVIDIA/gpu-feature-discovery
      gfd = {
        enabled = true;
      };
    };

  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings = [];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "nvidia_";
      inventory_path = "all/nvidia.yaml";
      unflat = [
        ["device_plugin" "helm" "values"]
      ];
      transformations = [
        (cfg:
          if config.yk8s.kubernetes.virtualize_gpu
          then cfg
          else builtins.removeAttrs cfg ["vgpu"])
      ];
    })
  ];
}
