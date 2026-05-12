{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  config.yk8s._targets.conf_vars.assertions = [];
  config.yk8s._targets.conf_vars.warnings = [];
  config.yk8s._targets.conf_vars = {
    inventory_subdir = "conf_vars";
    inventory_packages = [
      (yk8s-lib.mkYamlAtPath "main.yaml" [
        {
          tf_usage = config.yk8s.terraform.enabled;
          wg_usage = config.yk8s.wireguard.enabled;
          wg_subnet = config.yk8s.infra.subnet_cidr;
          wg_subnet_v6 = config.yk8s.infra.subnet_v6_cidr;
        }
      ])
    ];
  };
}
