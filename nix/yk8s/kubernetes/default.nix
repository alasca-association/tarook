{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModuleWithNewSection;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkInternalOption mkYaml;
  inherit
    (yk8s-lib.transform)
    warnIfZero
    filterNull
    ;
  inherit
    (yk8s-lib.types)
    k8sQuantity
    k8sVersion
    ;
in {
  imports = [
    ./monitoring.nix
    ./network.nix
    ./kubelet.nix
    (mkRemovedOptionModule "kubernetes" "use_podsecuritypolicies" "")
    (mkRemovedOptionModule "kubernetes" "continuous_join_key" "")
    (mkRenamedOptionModuleWithNewSection "kubernetes" "monitoring.alertmanager_config_secret" "k8s-service-layer.prometheus" "alertmanager_config_secret")
    (mkRemovedOptionModule "kubernetes" "global_monitoring" "This section has been moved to a custom role")
    (mkRemovedOptionModule "kubernetes" "apiserver.audit_logs.custom_policy" "Use config.yk8s.kubernetes.apiserver.audit_logs.policy instead")
    (mkRenamedOptionModuleWithNewSection "kubernetes" "storage.rook_enabled" "k8s-service-layer.rook" "enabled")
    (mkRenamedOptionModuleWithNewSection "kubernetes" "storage.cinder_enable_topology" "openstack" "cinder_enable_topology")
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
      type = k8sVersion [
        [1 31]
        [1 32]
        [1 33]
      ];
      # renovate: datasource=github-releases packageName=kubernetes/kubernetes
      default = "1.33.3";
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
    apiserver = {
      frontend_port = mkOption {
        type = types.port;
        default = 8888;
        apply = v:
          warnIfZero "config.yk8s.kubernetes.apiserver: should not be port zero" v;
      };
      memory_limit = mkOption {
        description = ''
          Memory resources limit for the apiserver
        '';
        type = types.nullOr k8sQuantity;
        default = null;
        example = "1Gi";
      };
      audit_logs = {
        enabled = mkEnableOption ''
          audit logs for the apiserver.

          .. note::

            Modifications to this setting and its related only apply during Kubernetes upgrades'';
        max_size = mkOption {
          description = ''
            Maximum size of apiserver audit log files in megabytes before it gets rotated
          '';
          type = types.ints.unsigned;
          default = 50;
        };
        policy = let
          defaultsFile = ./audit-policy-defaults.nix;
        in
          mkOption {
            description = ''
              The audit policy for the kube-apiserver.
              Checkout the
              `Kubernetes Auditing Documentation <https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/#audit-policy>`_
              for further information on how to configure.

              You may use ``audit_logs.policy = yk8s-lib.importYAML ./path/to/policy.yaml;`` to import
              an existing policy manifest. Note that the YAML file has to be added to the git repository
              in order to be evaluated by Nix.

              Alternatively, if you prefer to specify the policy in Nix directly, you may use
              https://github.com/cloudandheat/json2nix to convert existing policies to Nix.

              Note that this option is not type checked by Nix, so make sure that it it's a valid audit policy.
            '';

            example = lib.options.literalExample ''
              yk8s-lib.importYAML ./path/to/policy.yaml # Note that the file has to be added to the git repository to be evaluated by Nix
            '';
            type = lib.types.submodule {
              freeformType = lib.types.attrs;
            };
            default = import defaultsFile;

            # to include the comments in the docs
            defaultText = lib.options.literalExpression (builtins.readFile defaultsFile);
          };
        policy_file = mkInternalOption {
          readOnly = true;
          type = types.pathInStore;
          default = toString (mkYaml "audit-policy.yaml" (filterNull cfg.apiserver.audit_logs.policy));
        };
      };
    };
    controller_manager = {
      large_cluster_size_threshold = mkOption {
        type = types.ints.u32; # as per https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/#options
        default = 50;
      };
      enable_signing_requests = mkEnableOption ''
        signing requests.

        Note: This currently means that the cluster CA key is copied to the control
        plane nodes which decreases security compared to storing the CA only in the Vault.
        IMPORTANT: Manual steps required when enabled after cluster creation
        The CA key is made available through Vault's kv store and fetched by Ansible.
        Due to Vault's security architecture this means
        you must run the CA rotation script
        (or manually upload the CA key from your backup to Vault's kv store).
      '';
    };

    storage.nodeplugin_toleration = mkEnableOption ''
      nodeplugin toleration.
      Setting this to true will cause the storage plugins
      to run on all nodes (ignoring all taints). This is often desirable.
    '';
  };
  config.yk8s.assertions = [
    {
      assertion = ! (cfg.is_gpu_cluster && cfg.virtualize_gpu);
      message = "config.yk8s.kubernetes.is_gpu_cluster: is mutually exlusive with config.yk8s.kubernetes.virtualize_gpu";
    }
  ];
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "k8s_";
      inventory_path = "all/kubernetes.yaml";
      transformations = [
        # `apiserver.audit_logs.policy` is removed because it is proxied by `apiserver.audit_logs.policy_file`
        (cfg: yk8s-lib.transform.removeAttrByPath cfg ["apiserver" "audit_logs" "policy"])
      ];
    })
  ];
}
