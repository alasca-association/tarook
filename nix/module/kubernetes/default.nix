{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  removed-lib = import ../lib/removed.nix {inherit lib;};
  inherit (removed-lib) mkRemovedOptionModule;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  imports = [
    ./storage.nix
    ./monitoring.nix
    ./global-monitoring.nix
    ./network.nix
    ./kubelet.nix
    (mkRemovedOptionModule "kubernetes" "use_podsecuritypolicies" "")
    (mkRemovedOptionModule "kubernetes" "continuous_join_key" "") # TODO Not sure about that one
  ];
  options.yk8s.kubernetes = mkTopSection {
    version = mkOption {
      description = ''
        Kubernetes version
      '';
      type = types.strMatching "1\.(28|29)\.[0-9]+";
      default = "1.29.6";
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
    controller_manager.enable_signing_requests = mkEnableOption ''
      Note: This currently means that the cluster CA key is copied to the control
      plane nodes which decreases security compared to storing the CA only in the Vault.
      IMPORTANT: Manual steps required when enabled after cluster creation
        The CA key is made available through Vault's kv store and fetched by Ansible.
        Due to Vault's security architecture this means
        you must run the CA rotation script
        (or manually upload the CA key from your backup to Vault's kv store).
    '';
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "k8s_";
      inventory_path = "all/kubernetes.yaml";
    })
  ];
}
