{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.nodes;
  inherit (yk8s-lib) mkTopSection types;
in {
  options.yk8s.nodes = mkTopSection {
    # TODO make this actual submodules
    # deduplicate global options with openstack and proxmox
    # let openstack and proxmox fill these with their values
    # bare-metal should fill this instead of ansible_hosts directly
    groups = lib.mkOption {
      type = with types; attrsOf anything;
      default = {};
    };
    nodes = lib.mkOption {
      type = with types; attrsOf anything;
      default = {};
    };
  };
}
