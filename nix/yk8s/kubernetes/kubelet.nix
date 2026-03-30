{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.kubelet;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule;
  inherit (lib) mkOption mkEnableOption;
  inherit (yk8s-lib) mkOptional mkInternalOption types;
  kubeletSubmodule = types.submodule {
    freeformType = types.attrsOf types.yk8s.formats.jsonValue;
    options = {
      maxPods = mkOptional {
        description = "The maximum number of Pods that can run on this Kubelet. If unset, the kubeadm/kubelet default will be used.";
        type = types.ints.positive;
        example = 110;
      };
      evictionSoft = mkOptional {
        description = "A map of signal names to quantities that defines soft eviction thresholds. If unset, the kubeadm/kubelet default will be used.";
        type = types.attrsOf types.yk8s.formats.jsonValue;
        example = {
          "memory.available" = "300Mi";
        };
      };
      evictionSoftGracePeriod = mkOptional {
        description = "A map of signal names to quantities that defines grace periods for each soft eviction signal. If unset, the kubeadm/kubelet default will be used.";
        type = types.attrsOf types.yk8s.formats.jsonValue;
        example = {
          "memory.available" = "30s";
        };
      };
      evictionHard = mkOptional {
        description = "A map of signal names to quantities that defines hard eviction thresholds. If unset, the kubeadm/kubelet default will be used.";
        type = types.attrsOf types.yk8s.formats.jsonValue;
        example = {
          "memory.available" = "100Mi";
        };
      };
    };
  };
in {
  imports = [
    (mkRenamedOptionModule ["kubernetes" "kubelet" "pod_limit"] ["kubernetes" "kubelet" "pod_limit_worker"])
    (mkRenamedOptionModule ["kubernetes" "kubelet" "pod_limit_master"] ["kubernetes" "kubelet" "masterOptions" "maxPods"])
    (mkRenamedOptionModule ["kubernetes" "kubelet" "pod_limit_worker"] ["kubernetes" "kubelet" "workerOptions" "maxPods"])
    (mkRenamedOptionModule ["kubernetes" "kubelet" "evictionsoft_memory_period"] ["kubernetes" "kubelet" "defaultOptions" "evictionSoft" "memory.period"])
    (mkRenamedOptionModule ["kubernetes" "kubelet" "evictionhard_nodefs_available"] ["kubernetes" "kubelet" "defaultOptions" "evictionHard" "nodefs.available"])
    (mkRenamedOptionModule ["kubernetes" "kubelet" "evictionhard_nodefs_inodesfree"] ["kubernetes" "kubelet" "defaultOptions" "evictionHard" "nodesfs.inodesFree"])
  ];

  options.yk8s.kubernetes.kubelet = {
    defaultOptions = mkOption {
      description = ''
        Default kubelet configuration applied to all nodes.

        All options can be found in the official documentation:
        https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration

        Overrides can be specified per node:

        - :ref:`configuration-options.yk8s.kubernetes.kubelet.nodeOptions`

        or role:

        - :ref:`configuration-options.yk8s.kubernetes.kubelet.workerOptions`
        - :ref:`configuration-options.yk8s.kubernetes.kubelet.masterOptions`.

        .. warning::

          It is not validated whether the supplied configuration
          is a valid kubelet configuration.

      '';
      example = {
        maxPods = 110;
        evictionSoft = {
          "memory.available" = "384Mi";
        };
        evictionSoftGracePeriod = {
          "memory.available" = "1m25s";
        };
        evictionHard = {
          "memory.available" = "256Mi";
          "nodefs.available" = "12%";
          "imagefs.available" = "15%";
          "nodefs.inodesFree" = "7%";
        };
        imageGCLowThresholdPercent = 80;
        imageGCHighThresholdPercent = 85;
      };
      type = kubeletSubmodule;
      default = {};
    };
    masterOptions = mkOption {
      description = ''
        Kubelet configuration for master nodes.
        All options can be found in the official documentation: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration
        Overrides default configuration.

        .. warning::

          It is not validated whether the supplied configuration
          is a valid kubelet configuration.

      '';
      example = {
        maxPods = 110;
        evictionSoft = {
          "memory.available" = "384Mi";
        };
        evictionSoftGracePeriod = {
          "memory.available" = "1m25s";
        };
        evictionHard = {
          "memory.available" = "256Mi";
          "nodefs.available" = "12%";
          "imagefs.available" = "15%";
          "nodefs.inodesFree" = "7%";
        };
        imageGCLowThresholdPercent = 80;
        imageGCHighThresholdPercent = 85;
      };
      type = kubeletSubmodule;
      default = {};
    };
    workerOptions = mkOption {
      description = ''
        Kubelet configuration for worker nodes.
        All options can be found in the official documentation: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration
        Overrides default configuration.

        .. warning::

          It is not validated whether the supplied configuration
          is a valid kubelet configuration.

      '';
      example = {
        maxPods = 110;
        evictionSoft = {
          "memory.available" = "384Mi";
        };
        evictionSoftGracePeriod = {
          "memory.available" = "1m25s";
        };
        evictionHard = {
          "memory.available" = "256Mi";
          "nodefs.available" = "12%";
          "imagefs.available" = "15%";
          "nodefs.inodesFree" = "7%";
        };
        imageGCLowThresholdPercent = 80;
        imageGCHighThresholdPercent = 85;
      };
      type = kubeletSubmodule;
      default = {};
    };
    nodeOptions = mkOption {
      description = ''
        Node-specific kubelet configuration.
        All options can be found in the official documentation: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration
        Overrides default and role-specific configurations.

        .. attention::

          If :ref:`configuration-options.yk8s.openstack.enabled` is enabled,
          the full node name prefixed with :ref:`configuration-options.yk8s.infra.cluster_name` must be supplied.

        .. warning::

          It is not validated whether the supplied configuration
          is a valid kubelet configuration.

      '';
      example = {
        cluster-worker-1 = {
          maxPods = 110;
          evictionSoft = {
            "memory.available" = "384Mi";
          };
          evictionSoftGracePeriod = {
            "memory.available" = "1m25s";
          };
          evictionHard = {
            "memory.available" = "256Mi";
            "nodefs.available" = "12%";
            "imagefs.available" = "15%";
            "nodefs.inodesFree" = "7%";
          };
          imageGCLowThresholdPercent = 80;
          imageGCHighThresholdPercent = 85;
        };
        cluster-master-2.maxPods = 25;
      };
      type = types.attrsOf kubeletSubmodule;
      default = {};
    };
    finalNodeOptions = mkInternalOption {
      description = ''
        Final kubelet configuration for all nodes after merging all overrides and defaults.
      '';
      type = types.attrsOf kubeletSubmodule;
      readOnly = true;
      default =
        lib.mapAttrs (
          node: opts: let
            baseOptions = cfg.defaultOptions;
            roleOptions = builtins.getAttr opts.role {
              master = cfg.masterOptions;
              worker = cfg.workerOptions;
            };
            nodeSpecificOptions = cfg.nodeOptions.${node} or {};
          in
            builtins.foldl' lib.recursiveUpdate {} (map yk8s-lib.transform.filterNull [baseOptions roleOptions nodeSpecificOptions])
        )
        config.yk8s.infra.final_hosts.k8s_nodes.hosts;
    };
  };

  config.yk8s.kubernetes.kubelet.defaultOptions = {
    containerRuntimeEndpoint = lib.mkDefault "${config.yk8s.kubernetes.cri_url}";
  };

  config.yk8s._targets.ansible.assertions =
    lib.mapAttrsToList (
      nodeName: _: {
        assertion = builtins.elem nodeName (builtins.attrNames config.yk8s.infra.final_hosts.k8s_nodes.hosts);
        message = lib.concatStrings [
          "config.yk8s.kubernetes.kubelet.nodeOptions.${nodeName}:\n  "
          "kubelet options defined for '${nodeName}', "
          "but a node named '${nodeName}' can't be found in ${
            if config.yk8s.terraform.enabled
            then
              lib.concatStrings [
                "'config.yk8s.infra.ansible_hosts' (which is managed by Terraform).\n  "
                (lib.optionalString (!lib.hasPrefix config.yk8s.infra.cluster_name nodeName) ''
                  Did you specify the correct node name prefixed with '${config.yk8s.infra.cluster_name}-' ('config.yk8s.infra.cluster_name')?
                    Try changing: '${nodeName}' to '${config.yk8s.infra.cluster_name}-${nodeName}'
                '')
              ]
            else "'config.yk8s.infra.ansible_hosts'."
          }"
        ];
      }
    )
    cfg.nodeOptions;
}
