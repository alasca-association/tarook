{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.node-scheduling;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  options.yk8s.node-scheduling = mkTopSection {
    scheduling_key_prefix = mkOption {
      description = ''
        Scheduling keys control where services may run. A scheduling key corresponds
        to both a node label and to a taint. In order for a service to run on a node,
        it needs to have that label key. The following defines a prefix for these keys
      '';
      type = types.str;
      default = "scheduling.mk8s.cloudandheat.com";
    };
    labels = mkOption {
      description = ''
        Labels are assigned to a node during its initialization/join process only!
      '';
      type = with types; attrsOf (listOf str);
      default = {};
      example = ''
        {
          managed-k8s-worker-0 = ["''${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true"];
          managed-k8s-worker-1 = ["''${config.yk8s.node-scheduling.scheduling_key_prefix}/monitoring=true"];
          managed-k8s-worker-2 = ["''${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true"];
          managed-k8s-worker-3 = ["''${config.yk8s.node-scheduling.scheduling_key_prefix}/monitoring=true"];
          managed-k8s-worker-4 = ["''${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true"];
          managed-k8s-worker-5 = ["''${config.yk8s.node-scheduling.scheduling_key_prefix}/monitoring=true"];
        }
      '';
    };
    taints = mkOption {
      description = ''
        Taints are assigned to a node during its initialization/join process only!
      '';
      type = with types; attrsOf (listOf str);
      default = {};
      example = ''
        {
          managed-k8s-worker-0 = ["{{ scheduling_key_prefix }}/storage=true:NoSchedule"];
          managed-k8s-worker-2 = ["{{ scheduling_key_prefix }}/storage=true:NoSchedule"];
          managed-k8s-worker-4 = ["{{ scheduling_key_prefix }}/storage=true:NoSchedule"];
        }
      '';
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/node-scheduling.yaml";
      transformations = [
        (lib.attrsets.mapAttrs' (name: value: {
          name =
            if builtins.elem name ["labels" "taints"]
            then "k8s_node_${name}"
            else name;
          inherit value;
        }))
      ];
    })
  ];
}
