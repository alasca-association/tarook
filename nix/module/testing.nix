{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.testing;
  inherit (builtins) length;
  inherit (lib) mkOption types;
  inherit (config.yk8s._lib) mkTopSection logIf;
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
    };
    force_reboot_nodes = mkOption {
      description = ''
      Enforce rebooting of nodes after every system update
      '';
      type = types.bool;
      default = false;
    };
  };
  config.yk8s.testing = {
    _ansible_prefix = "testing_";
    _inventory_path = "all/test-nodes.yaml";
  };
  config.yk8s._errors = logIf ((length cfg.test-nodes) == 1 )
  "[testing] If you define any node, then must specify at least two";
}
