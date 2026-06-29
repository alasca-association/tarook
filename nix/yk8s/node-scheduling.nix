{
  options,
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.node-scheduling;
  opts = options.yk8s.node-scheduling;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
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
    };
    labels = mkOption {
      description = ''
        Labels are assigned to a node during LCM rollout only!
      '';
      type = with types; attrsOf (listOf yk8s.k8s.labelStr);
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
    };
    taints = mkOption {
      description = ''
        Taints are assigned to a node during LCM rollout only!
      '';
      type = with types; attrsOf (listOf yk8s.k8s.taintStr);
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
    };
  };
  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings =
    (builtins.foldl' (acc: e:
      acc
      ++ lib.optional (! builtins.hasAttr e (config.yk8s.infra.final_hosts.all.hosts or {}))
      "config.yk8s.node-scheduling.labels: label defined for ${e}, but node not found in config.yk8s.infra.ansible_hosts") [] (builtins.attrNames cfg.labels))
    ++ (builtins.foldl' (acc: e:
      acc
      ++ lib.optional (! builtins.hasAttr e (config.yk8s.infra.final_hosts.all.hosts or {}))
      "config.yk8s.node-scheduling.taints: taint defined for ${e}, but node not found in config.yk8s.infra.ansible_hosts") [] (builtins.attrNames cfg.taints))
    # Produce warning if option is used
    ++ lib.optional
    (opts.scheduling_key_prefix.highestPrio < 1500) # priority of option defaults
    
    "config.yk8s.node-scheduling.scheduling_key_prefix: is deprecated. Please substitute with a let expression.";
  config.yk8s._targets.ansible.inventory_packages = [
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
      unflat = [
        ["k8s_node_labels"]
        ["k8s_node_taints"]
      ];
    })
  ];
}
