{
  lib,
  config,
  ...
}: let
  cfg = config.yk8s.openstack;
in {
  yk8s.terraform.modules = lib.optional cfg.enabled {
    terraform.required_providers = {
      openstack = {
        source = "terraform-provider-openstack/openstack";
        version = "~> 3.4.0";
      };
    };
    provider.openstack = {};
  };
}
