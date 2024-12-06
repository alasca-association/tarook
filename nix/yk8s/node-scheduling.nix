{
  options,
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.node-scheduling;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
  nodeNames = map (n: "${config.yk8s.infra.cluster_name}-${n}") (builtins.attrNames config.yk8s.openstack.nodes);
  inherit
    (yk8s-lib.types)
    k8sLabelStr
    k8sTaintStr
    ;
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

    # TODO: Remove deprecated option
    scheduling_key_prefix = mkOption {
      description = ''
        .. note:: DEPRECATED

           This option is going to be removed. Please use Nix's let expression instead.

        Scheduling keys control where services may run. A scheduling key corresponds
        to both a node label and to a taint. In order for a service to run on a node,
        it needs to have that label key. The following defines a prefix for these keys
      '';
      type = types.str;
      default = "scheduling.mk8s.cloudandheat.com";
      # Output deprecation warning if used
      apply = v:
        lib.warn "config.yk8s.node-scheduling.scheduling_key_prefix: is deprecated. Please substitute with a let expression." v;
    };
    labels = mkOption {
      description = ''
        Labels are assigned to a node during LCM rollout only!
      '';
      type = with types; attrsOf (listOf k8sLabelStr);
      default = {};
      example = lib.options.literalExpression ''
        {
          managed-k8s-worker-0 = [
            "''${scheduling_key_prefix}/storage=true"
          ];
          managed-k8s-worker-1 = [
            "''${scheduling_key_prefix}/monitoring=true"
          ];
          managed-k8s-worker-2 = [
            "''${scheduling_key_prefix}/storage=true"
          ];
          managed-k8s-worker-3 = [
            "''${scheduling_key_prefix}/monitoring=true"
          ];
          managed-k8s-worker-4 = [
            "''${scheduling_key_prefix}/storage=true"
          ];
          managed-k8s-worker-5 = [
            "''${scheduling_key_prefix}/monitoring=true"
          ];
        }'';
      apply = v:
        builtins.seq (builtins.all (e:
          if config.yk8s.terraform.enabled -> builtins.elem e nodeNames
          then true
          else throw "config.yk8s.node-scheduling.labels: label defined for ${e}, but node not found in config.yk8s.openstack.nodes") (builtins.attrNames v))
        v;
    };
    taints = mkOption {
      description = ''
        Taints are assigned to a node during LCM rollout only!
      '';
      type = with types; attrsOf (listOf k8sTaintStr);
      default = {};
      example = lib.options.literalExpression ''
        {
          managed-k8s-worker-0 = [
            "''${scheduling_key_prefix}/storage=true:NoSchedule"
          ];
          managed-k8s-worker-2 = [
            "''${scheduling_key_prefix}/storage=true:NoSchedule"
          ];
          managed-k8s-worker-4 = [
            "''${scheduling_key_prefix}/storage=true:NoSchedule"
          ];
        }'';
      apply = v:
        builtins.seq (builtins.all (e:
          if config.yk8s.terraform.enabled -> builtins.elem e nodeNames
          then true
          else throw "config.yk8s.node-scheduling.taints: taint defined for ${e}, but node not found in config.yk8s.openstack.nodes") (builtins.attrNames v))
        v;
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/node-scheduling.yaml";
      transformations = [
        # TODO: remove when deprecated scheduling_key_prefix is dropped
        (lib.attrsets.filterAttrs (n: _: ! (builtins.elem n ["scheduling_key_prefix"])))
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
