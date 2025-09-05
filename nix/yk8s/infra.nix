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
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkDisableOption linkToPath types;
in {
  options.yk8s.infra = mkTopSection {
    _docs.preface = ''
      This section contains various configuration options necessary for all
      cluster types, Terraform and bare-metal based.
    '';

    cluster_name = mkOption {
      # NOTE: empty or spaced strings must never by accepted here
      type = types.yk8s.k8s.clusterName;
      description = ''
        Name of the cluster that is to be build and managed.

        Used to distinguish the cluster from others
        and to name harbour infrastructure resources.
      '';
    };

    ipv4_enabled = mkDisableOption "IPv4";

    ipv6_enabled = mkEnableOption "IPv6";

    subnet_cidr = mkOption {
      type = types.yk8s.networking.ipv4Cidr;
      default = "172.30.154.0/24";
      description = ''
        The IPv4 CIDR of the internally used network.
        Only applies if :ref:`configuration-options.yk8s.infra.ipv4_enabled` is set to ``true``.
      '';
      apply = v:
        if ! cfg.ipv4_enabled
        then null
        else v;
    };

    subnet_v6_cidr = mkOption {
      type = types.yk8s.networking.ipv6Cidr;
      default = "fd00::/120";
      description = ''
        The IPv6 CIDR of the internally used network.
        Only applies if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is set to ``true``.
      '';
      apply = v:
        if ! cfg.ipv6_enabled
        then null
        else v;
    };

    networking_fixed_ip = mkOption {
      type = types.nullOr types.yk8s.networking.ipv4Addr;
      default = null;
      apply = v:
        if v == null && cfg.ipv4_enabled && config.yk8s.openstack.enabled == false
        then throw "config.yk8s.infra.networking_fixed_ip must be set if config.yk8s.infra.ipv4_enabled=true and config.yk8s.openstack.enabled=false"
        else if v != null && config.yk8s.openstack.enabled == true
        then throw "config.yk8s.infra.networking_fixed_ip must not be set if config.yk8s.openstack.enabled=true"
        else v;
    };

    networking_fixed_ip_v6 = mkOption {
      type = with types; nullOr types.yk8s.networking.ipv6Addr;
      default = null;
      apply = v:
        if v == null && cfg.ipv6_enabled && config.yk8s.openstack.enabled == false
        then throw "config.yk8s.infra.networking_fixed_ip_v6 must be set if config.yk8s.infra.ipv6_enabled=true and config.yk8s.openstack.enabled=false"
        else if v != null && config.yk8s.openstack.enabled == true
        then throw "config.yk8s.infra.networking_fixed_ip_v6 must not be set if config.yk8s.openstack.enabled=true"
        else v;
    };

    hosts_file = mkOption {
      description = ''
        A custom hosts file in case :ref:`configuration-options.yk8s.openstack.enabled` is set to ``false``
      '';
      type = with types; nullOr pathInStore;
      default = null;
      example = lib.options.literalExpression "./hosts";
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
        transformations =
          [(lib.attrsets.filterAttrs (n: _: n != "hosts_file"))]
          ++ (lib.optional config.yk8s.openstack.enabled (lib.attrsets.filterAttrs (n: _: ! (builtins.elem n ["networking_fixed_ip" "networking_fixed_ip_v6"]))));
      })
    ]
    ++ lib.optional (cfg.hosts_file != null)
    (linkToPath cfg.hosts_file "hosts");
}
