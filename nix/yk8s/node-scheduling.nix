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
    _docs.preface = ''
      .. note::
        Nodes get their labels and taints during LCM rollout.
        Once a node has joined the cluster,
        its labels and taints can only be changed or new ones be added.
        Removal is currently not supported.

      More details about the labels and taints configuration can be found
      :doc:`here </user/explanation/node-scheduling>`.
    '';

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
        Labels are assigned to a node during LCM rollout only!
      '';
      type = with types; attrsOf (listOf nonEmptyStr);
      default = {};
      example = {
        managed-k8s-worker-0 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true"];
        managed-k8s-worker-1 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/monitoring=true"];
        managed-k8s-worker-2 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true"];
        managed-k8s-worker-3 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/monitoring=true"];
        managed-k8s-worker-4 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true"];
        managed-k8s-worker-5 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/monitoring=true"];
      };
    };
    taints = mkOption {
      description = ''
        Taints are assigned to a node during LCM rollout only!
      '';
      type = with types; attrsOf (listOf nonEmptyStr);
      default = {};
      example = {
        managed-k8s-worker-0 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true:NoSchedule"];
        managed-k8s-worker-2 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true:NoSchedule"];
        managed-k8s-worker-4 = ["\${config.yk8s.node-scheduling.scheduling_key_prefix}/storage=true:NoSchedule"];
      };
    };
  };
  config.yk8s.warnings =
    (builtins.foldl' (acc: e:
      acc
      ++ lib.optional (! builtins.hasAttr e config.yk8s.infra.final_hosts)
      "(node-scheduling) Label defined for ${e}, but node not found in infra.ansible_hosts") [] (builtins.attrNames cfg.labels))
    ++ (builtins.foldl' (acc: e:
      acc
      ++ lib.optional (! builtins.hasAttr e config.yk8s.infra.final_hosts)
      "(node-scheduling) Taint defined for ${e}, but node not found in infra.ansible_hosts") [] (builtins.attrNames cfg.taints));
  config.yk8s._targets.ansible.inventory_packages = [
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
      unflat = ["k8s_node_labels" "k8s_node_taints"];
    })
  ];
}
