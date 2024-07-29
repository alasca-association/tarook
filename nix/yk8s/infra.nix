{
  config,
  pkgs,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.infra;
  removed-lib = import ./lib/removed.nix {inherit lib;};
  inherit (removed-lib) mkRemovedOptionModule;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile linkToPath;
  inherit (yk8s-lib.types) ipv4Cidr ipv4Addr;
in {
  options.yk8s.infra = mkTopSection {
    _docs.preface = ''
      .. _cluster-configuration.infra-configuration:

      Infra Configuration
      ^^^^^^^^^^^^^^^^^^^

      This section contains various configuration options necessary for all
      cluster types, Terraform-based or bare-metal.
    '';

    ipv4_enabled = mkOption {
      description = ''
        If set to true, ipv4 will be used
      '';
      type = types.bool;
      default = true;
    };

    ipv6_enabled = mkOption {
      description = ''
        If set to true, ipv6 will be used
      '';
      type = types.bool;
      default = false;
    };

    subnet_cidr = mkOption {
      type = ipv4Cidr;
      default = "172.30.154.0/24";
    };

    subnet_v6_cidr = mkOption {
      type = types.str;
      default = "fd00::/120";
    };

    hosts_file = mkOption {
      description = ''
        A custom hosts file in case terraform is disabled
      '';
      type = with types; nullOr pathInStore;
      default = null;
      example = "./hosts";
      apply = v:
        if v == null && config.yk8s.terraform.enabled == false
        then throw "infra.hosts_file must be set if terraform is disabled"
        else if v != null && config.yk8s.terraform.enabled == true
        then throw "infra.hosts_file must not be set if terraform is enabled"
        else v;
    };
  };
  config.yk8s._inventory_packages =
    [
      (mkGroupVarsFile {
        inherit cfg;
        inventory_path = "all/infra.yaml";
        transformations = [(lib.attrsets.filterAttrs (n: _: n != "hosts_file"))];
      })
    ]
    ++ lib.optional (cfg.hosts_file != null)
    (linkToPath cfg.hosts_file "hosts");
}
