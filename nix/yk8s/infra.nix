{
  config,
  pkgs,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.infra;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
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
      cluster types, Terraform and bare-metal based.
    '';

    cluster_name = mkOption {
      type = types.nonEmptyStr;
    };

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
      type = types.nonEmptyStr;
      default = "fd00::/120";
    };

    networking_fixed_ip = mkOption {
      type = types.nullOr ipv4Addr;
      default = null;
      apply = v:
        if cfg.ipv4_enabled && v == null && config.yk8s.terraform.enabled
        then builtins.trace "INFO: infra.networking_fixed_ip is not yet set. Terraform stage needs to be run first." v
        else v;
    };

    networking_fixed_ip_v6 = mkOption {
      type = with types; nullOr nonEmptyStr;
      default = null;
      apply = v:
        if cfg.ipv6_enabled && v == null && config.yk8s.terraform.enabled
        then builtins.trace "INFO: infra.networking_fixed_ip_v6 is not yet set. Terraform stage needs to be run first." v
        else v;
    };

    hosts_file = mkOption {
      description = ''
        A custom hosts file in case openstack is disabled
      '';
      type = with types; nullOr pathInStore;
      default = null;
      example = "./hosts";
      apply = v:
        if v == null && config.yk8s.openstack.enabled == false
        then throw "infra.hosts_file must be set if openstack is disabled"
        else if v != null && config.yk8s.openstack.enabled == true
        then throw "infra.hosts_file must not be set if openstack is enabled"
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
