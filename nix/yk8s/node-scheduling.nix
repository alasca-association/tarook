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
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types mkInternalOption;
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

        Can be set to ``null`` in order to remove the label.
      '';
      type = with types; attrsOf (either (listOf yk8s.k8s.labelStr) (attrsOf (nullOr yk8s.k8s.labelValue)));
      default = {};
      example = {
        managed-k8s-worker-0."example.org/storage" = "true";
        managed-k8s-worker-0."example.org/monitoring" = "true";
        managed-k8s-worker-1 = ["example.org/storage=true" "example.org/monitoring=true"];
        managed-k8s-worker-2."example.org/storage" = null;
        managed-k8s-worker-2."example.org/monitoring" = null;
      };
      apply = let
        labelListToAttrs = builtins.foldl' (acc: labelStr: let
          m = builtins.match "(.*)=(.*)" labelStr;
          label = builtins.elemAt m 0;
          value = builtins.elemAt m 1;
        in
          acc
          // {
            ${label} = value;
          }) {};
      in
        lib.mapAttrs (
          nodeName: nodeLabels:
            if builtins.isAttrs nodeLabels
            then nodeLabels
            else
              labelListToAttrs
              nodeLabels
        );
    };
    taints = mkOption {
      description = ''
        Taints are assigned to a node during LCM rollout only!

        Can be set to ``null`` in order to remove the taint.
      '';
      type = with types;
        attrsOf (either (listOf yk8s.k8s.taintStr) (attrsOf (nullOr (submodule {
          options = {
            value = mkOption {
              type = nullOr yk8s.k8s.labelValue;
              default = null;
            };
            effect = mkOption {
              type = enum ["NoExecute" "NoSchedule" "PreferNoSchedule"];
              default = "NoExecute";
            };
          };
        }))));
      default = {};
      example = {
        managed-k8s-worker-0."examply.org/storage" = {
          value = "true";
          effect = "NoSchedule";
        };
        managed-k8s-worker-2 = ["example.org/storage=true:NoSchedule"];
        managed-k8s-worker-4."examply.org/storage" = null;
      };
      apply = let
        taintListToAttrs = builtins.foldl' (acc: taintStr: let
          m = builtins.match "^([^:=]+)([=]([^:]+))?([:](.+))?" taintStr;
          taint = builtins.elemAt m 0;
          value = builtins.elemAt m 2;
          effect = let
            e = builtins.elemAt m 4;
          in
            if e != null
            then e
            else "NoExecute";
        in
          acc
          // {
            ${taint} = {inherit value effect;};
          }) {};
      in
        lib.mapAttrs (
          nodeName: nodeTaints:
            if builtins.isAttrs nodeTaints
            then nodeTaints
            else taintListToAttrs nodeTaints
        );
    };
    taints_present = mkInternalOption {
      readOnly = true;
      type = with types; attrsOf (listOf attrs);
      default =
        lib.mapAttrs (
          _: nodeTaints:
            lib.mapAttrsToList (key: {
              value,
              effect,
            }: {inherit key value effect;})
            (lib.filterAttrs (_: v: v != null) nodeTaints)
        )
        cfg.taints;
    };
    taints_absent = mkInternalOption {
      readOnly = true;
      type = with types; attrsOf (listOf attrs);
      default =
        lib.mapAttrs (
          _: nodeTaints:
            lib.mapAttrsToList (key: _: {inherit key;})
            (lib.filterAttrs (_: v: v == null) nodeTaints)
        )
        cfg.taints;
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
    
    "config.yk8s.node-scheduling.scheduling_key_prefix: is deprecated. Please substitute with a let expression."
    ++ (builtins.foldl' (acc: e:
      acc
      ++ lib.optional (config.yk8s.terraform.outputs_ready && ! builtins.hasAttr e (config.yk8s.infra.final_hosts.all.hosts or {}))
      "config.yk8s.node-scheduling.taints: taint defined for ${e}, but node not found in config.yk8s.infra.ansible_hosts") [] (builtins.attrNames cfg.taints));
  config.yk8s.node-scheduling.labels =
    (
      lib.mapAttrs (
        workerName: _: {
          "node-role.kubernetes.io/worker" = "";
          "node-role.kubernetes.io/control-plane" = null;
        }
      )
      (config.yk8s.infra.ansible_hosts.workers.hosts or {})
    )
    // (
      lib.mapAttrs (masterName: _: {
        "node-role.kubernetes.io/control-plane" = "";
        "node-role.kubernetes.io/worker" = null;
      })
      (config.yk8s.infra.ansible_hosts.masters.hosts or {})
    );
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/node-scheduling.yaml";
      transformations = [
        # TODO: remove when deprecated scheduling_key_prefix is dropped
        (lib.attrsets.filterAttrs (n: _: ! (builtins.elem n ["scheduling_key_prefix"])))
        (lib.attrsets.filterAttrs (name: _: name != "taints"))
        (lib.attrsets.mapAttrs' (name: value: {
          name =
            if builtins.elem name ["labels" "taints_present" "taints_absent"]
            then "k8s_node_${name}"
            else name;
          inherit value;
        }))
      ];
      unflat = [
        ["k8s_node_labels"]
        ["k8s_node_taints_present"]
        ["k8s_node_taints_absent"]
      ];
    })
  ];
}
