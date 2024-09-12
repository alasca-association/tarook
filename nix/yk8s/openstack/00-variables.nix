{
  lib,
  config,
  ...
}: let
  cfg = config.yk8s.openstack;
in {
  yk8s.terraform.modules = lib.optional cfg.enabled {
    variable.keypair.type = "string";
  };
}
