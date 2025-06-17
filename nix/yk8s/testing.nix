{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.testing;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  imports = [
    (mkRenamedOptionModule "testing" "test-nodes" "nodes")
  ];
  options.yk8s.testing = mkTopSection {
    _docs.preface = ''
      The following configuration section can be used to ensure that smoke
      tests and checks are executed from different nodes. This is disabled by
      default as it requires some prethinking.
    '';

    nodes = mkOption {
      description = ''
        You can define specific nodes for some
        smoke tests. If you define these, you
        must specify at least two nodes.
      '';
      type = with types; listOf nonEmptyStr;
      default = [];
    };
    force_reboot_nodes = mkOption {
      description = ''
        Enforce rebooting of nodes after every system update
      '';
      type = types.bool;
      default = false;
    };
  };
  config.yk8s.assertions = let
    inherit (builtins) all attrNames elem filter length;
    inherit (lib.strings) concatStringsSep;
    openstackNodesWithPrefix = map (n: "${config.yk8s.infra.cluster_name}-${n}") (attrNames config.yk8s.openstack.nodes);
    nonExistentNodes = filter (node: ! elem node openstackNodesWithPrefix) cfg.nodes;
  in [
    {
      assertion = length cfg.nodes != 1;
      message = "config.yk8s.testing.nodes: must at least specify two nodes or none";
    }
    {
      assertion = config.yk8s.openstack.enabled -> nonExistentNodes == [];
      message = "config.yk8s.testing.nodes: nodes [${concatStringsSep ", " nonExistentNodes}] don't exist. Note that full hostnames including the prefix '${config.yk8s.infra.cluster_name}-' must be supplied.";
    }
  ];
  config.yk8s._inventory_packages = [
    (
      mkGroupVarsFile {
        inherit cfg;
        ansible_prefix = "testing_";
        inventory_path = "all/test-nodes.yaml";
      }
    )
  ];
}
