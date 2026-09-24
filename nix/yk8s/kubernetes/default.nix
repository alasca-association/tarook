{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModule;
  inherit (lib) mkOption mkEnableOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkInternalOption mkYaml types;
  inherit
    (yk8s-lib.transform)
    filterNull
    ;
in {
  imports = [
    ./apiserver
    ./monitoring.nix
    ./network.nix
    ./kubelet.nix
    ./kubeadm
    (mkRemovedOptionModule ["kubernetes" "use_podsecuritypolicies"] "")
    (mkRemovedOptionModule ["kubernetes" "continuous_join_key"] "")
    (mkRenamedOptionModule ["kubernetes" "monitoring" "alertmanager_config_secret"] ["k8s-service-layer" "prometheus" "alertmanager_config_secret"])
    (mkRemovedOptionModule ["kubernetes" "global_monitoring"] "This section has been moved to a custom role")
    (mkRenamedOptionModule ["kubernetes" "storage" "rook_enabled"] ["k8s-service-layer" "rook" "enabled"])
    (mkRenamedOptionModule ["kubernetes" "storage" "cinder_enable_topology"] ["openstack" "cinder_enable_topology"])
  ];
  options.yk8s.kubernetes = mkTopSection {
    _docs.order = 3;
    _docs.preface = ''
      This section contains generic information about the Kubernetes cluster
      configuration.
    '';

    version = mkOption {
      description = ''
        Kubernetes version
      '';
      type = types.yk8s.k8s.kubernetesVersions [
        [1 33]
        [1 34]
        [1 35]
        [1 36]
      ];
      # renovate: datasource=github-releases packageName=kubernetes/kubernetes
      default = "1.36.4";
    };

    cri_url = mkInternalOption {
      type = types.yk8s.networking.urlWith {schemeRE = "unix";};
      default = "unix:///var/run/containerd/containerd.sock";
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
    virtualize_gpu = mkEnableOption ''
      virtualization of Nvidia GPUs on worker nodes.
      Set this variable to virtualize Nvidia GPUs on worker nodes
      for usage outside of the Kubernetes cluster / above the Kubernetes layer.
      It will install a VGPU manager on the worker node and
      split the GPU according to chosen vgpu type.
      Note: This will not install Nvidia drivers to utilize vGPU guest VMs!!
      If set to true, please set further variables in :ref:`configuration-options.yk8s.miscellaneous`.
      Note: This is mutually exclusive with :ref:`configuration-options.yk8s.kubernetes.is_gpu_cluster`.
    '';
    controller_manager = {
      large_cluster_size_threshold = mkOption {
        type = types.ints.u32; # as per https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/#options
        default = 50;
      };
      enable_signing_requests = mkEnableOption ''
        signing requests.

        Note: This currently means that the cluster CA key is copied to the control
        plane nodes which decreases security compared to storing the CA only in the Vault.

        .. important::

           Manual steps required when enabled after cluster creation.
           The CA key is made available through Vault's kv store and fetched by Ansible.
           Due to Vault's security architecture this means
           you must run the CA rotation script (see :doc:`/user/guide/vault/vault-ca-rotation`)
           or manually upload the CA key from your backup to Vault's kv store.

      '';
    };

    storage.nodeplugin_toleration = mkEnableOption ''
      nodeplugin toleration.
      Setting this to true will cause the storage plugins
      to run on all nodes (ignoring all taints). This is often desirable.
    '';
  };
  config.yk8s._targets.ansible.assertions = [
    {
      assertion = ! (cfg.is_gpu_cluster && cfg.virtualize_gpu);
      message = "config.yk8s.kubernetes.is_gpu_cluster: is mutually exlusive with config.yk8s.kubernetes.virtualize_gpu";
    }
  ];
  config.yk8s.warnings =
    []
    ++ lib.optional
    (yk8s-lib.transform.matchesRegex "^(${types.yk8s.networking._regexes.rfc3986.schemeRE})://[^/].*$" cfg.cri_url)
    "config.yk8s.kubernetes.cri_url uses a relative path which may lead to unintended behavior."
    ++ lib.optional (cfg.apiserver.frontend_port == 0)
    "config.yk8s.kubernetes.apiserver.frontend_port: should not be port zero";
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "k8s_";
      inventory_path = "all/kubernetes.yaml";
      transformations = [
        (cfg:
          yk8s-lib.transform.removeAttrsByPath cfg [
            ["apiserver" "audit_logs" "policy"] # proxied by apiserver.audit_logs.policy_file
            ["kubelet" "masterOptions"] # merged into kubelet.finalNodeOptions
            ["kubelet" "nodeOptions"] # merged into kubelet.finalNodeOptions
            ["kubelet" "workerOptions"] # merged into kubelet.finalNodeOptions
            ["kubeadm" "patches"] # proxied by kubeadm.patches_dir
            ["kubeadm" "clusterConfiguration"] # proxied by kubeadm.initConfigurationBundles
            ["kubeadm" "initConfigurations"] # proxied by kubeadm.initConfigurationBundles and kubeadm.initConfigurationFiles
            ["kubeadm" "joinConfigurations"] # proxied by kubeadm.joinConfigurationFiles
          ])
        # recusively filter null values on kubelet subset
        (lib.updateManyAttrsByPath [
          {
            path = ["kubelet"];
            update = yk8s-lib.transform.filterNull;
          }
        ])
      ];
      unflat = [
        ["kubeadm" "initConfigurationBundles"]
        ["kubeadm" "initConfigurationFiles"]
        ["kubeadm" "joinConfigurationFiles"]
        ["kubelet" "defaultOptions"]
        ["kubelet" "finalNodeOptions"]
        ["network" "calico" "helm" "values"]
      ];
    })
  ];
}
