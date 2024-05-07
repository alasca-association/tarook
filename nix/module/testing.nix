{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.testing;
  inherit (builtins) length;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  options.yk8s.testing = mkTopSection {
    test-nodes = mkOption {
      description = ''
        You can define specifc nodes for some
        smoke tests. If you define these, you
        must specify at least two nodes.
      '';
      type = with types; listOf str;
      default = [];
      apply = v:
        if length v == 1
        then
          throw
          "[testing.test-nodes] If you define any node, then must specify at least two"
        else v;
    };
    force_reboot_nodes = mkOption {
      description = ''
        Enforce rebooting of nodes after every system update
      '';
      type = types.bool;
      default = false;
    };
  };
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
