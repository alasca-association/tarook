{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  inherit (lib) mkOption types;
  inherit (config.yk8s._lib) mkInternalOption;
in {
  imports = [
    ./storage.nix
    ./monitoring.nix
    ./global-monitoring.nix
    ./network.nix
    ./kubelet.nix
  ];
  options.yk8s.kubernetes = {
    version = mkOption {
      description = ''
        Kubernetes version
      '';
      type = types.strMatching "1\.(26|27|28)\.[0-9]+";
      default = "1.28.9";
    };
    is_gpu_cluster = mkOption {
      description = ''
        Set this variable if this cluster contains worker with GPU access
        and you want to make use of these inside of the cluster,
        so that the driver and surrounding framework is deployed.
      '';
      type = types.bool;
      default = false;
    };
    virtualize_gpu = mkOption {
      description = ''
        Set this variable to virtualize Nvidia GPUs on worker nodes
        for usage outside of the Kubernetes cluster / above the Kubernetes layer.
        It will install a VGPU manager on the worker node and
        split the GPU according to chosen vgpu type.
        Note: This will not install Nvidia drivers to utilize vGPU guest VMs!!
        If set to true, please set further variables in the [miscellaneous] section.
        Note: This is mutually exclusive with "is_gpu_cluster"yed.
      '';
      type = types.bool;
      default = false;
    };
    apiserver = {
      frontend_port = mkOption {
        type = types.port;
        default = 8888;
      };
      memory_limit = mkOption {
        description = ''
          Memory resources limit for the apiserver
        '';
        type = types.nullOr types.str;
        default = null;
        example = "1Gi";
      };
    };
    controller_manager.large_cluster_size_threshold = mkOption {
      type = types.int;
      default = 50;
    };

    _ansible_prefix = mkInternalOption {
      type = types.str;
      default = "k8s_";
    };
    _inventory_path = mkInternalOption {
      type = types.str;
      default = "all/kubernetes.yaml";
    };
  };
}
