{
  config,
  lib,
  yk8s-lib,
  pkgs,
  ...
}: let
  cfg = config.yk8s.wireguard;
  modules-lib = import ../../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkRemovedOptionModule;
  inherit (lib) mkOption types;
  inherit (lib.attrsets) filterAttrs;
  inherit (yk8s-lib) mkTopSection;
  inherit (yk8s-lib.types) ipv4Addr ipv4Cidr;
  # inherit (yk8s-lib.transform) filterNull addPrefix;
  inherit (yk8s-lib) linkToPath;
  inherit (yk8s-lib.transform) removeObsoleteOptions filterNull filterInternal;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (builtins) foldl' elem fromJSON readFile toString;
  inherit (lib.trivial) pipe;
in {
  imports = [
    (mkRenamedOptionModule "wireguard" "wg_ip_cidr" "ip_cidr")
    (mkRenamedOptionModule "wireguard" "wg_ipv6_cidr" "ipv6_cidr")
    (mkRemovedOptionModule "wireguard" "rollout_company_users" "")
    (mkRemovedOptionModule "wireguard" "s2s_enabled" "")
  ];

  options.yk8s.wireguard = mkTopSection {
    _docs.preface = ''
      You **MUST** add yourself to the :doc:`wireguard </user/explanation/vpn/wireguard>`
      peers.

      You can do so either in the following section of the config file or by
      using and configuring a git submodule. This submodule would then refer
      to another repository, holding the wireguard public keys of everybody
      that should have access to the cluster by default. This is the
      recommended approach for companies and organizations.
    '';

    enabled = mkOption {
      type = types.bool;
      default = true;
    };

    port = mkOption {
      description = ''
        DEPRECATED. Use endpoints instead

        The port Wireguard should use on the frontend nodes
      '';
      type = with types; nullOr port;
      default = null;
      example = 7777;
    };
    ip_cidr = mkOption {
      description = ''
        DEPRECATED. Use endpoints instead

        IP address range to use for WireGuard clients. Must be set to a CIDR and must
        not conflict with the terraform.subnet_cidr.
        Should be chosen uniquely for all clusters of a customer at the very least
        so that they can use all of their clusters at the same time without having
        to tear down tunnels.
      '';
      type = types.nullOr ipv4Cidr;
      default = null;
      example = "172.30.153.64/26";
    };
    ip_gw = mkOption {
      description = ''
        DEPRECATED. Use endpoints instead

        IP address range to use for WireGuard servers. Must be set to a CIDR and must
        not conflict with the terraform.subnet_cidr.
        Should be chosen uniquely for all clusters of a customer at the very least
        so that they can use all of their clusters at the same time without having
        to tear down tunnels.
      '';
      type = types.nullOr ipv4Cidr;
      default = null;
      example = "172.30.153.65/26";
    };

    ipv6_cidr = mkOption {
      description = ''
        DEPRECATED. Use endpoints instead

        IP address range to use for WireGuard clients. Must be set to a CIDR and must
        not conflict with the terraform.subnet_cidr.
        Should be chosen uniquely for all clusters of a customer at the very least
        so that they can use all of their clusters at the same time without having
        to tear down tunnels.
      '';
      type = types.nullOr types.nonEmptyStr;
      default = null;
      example = "fd01::/120";
    };
    ipv6_gw = mkOption {
      description = ''
        DEPRECATED. Use endpoints instead

        IP address range to use for WireGuard servers. Must be set to a CIDR and must
        not conflict with the terraform.subnet_cidr.
        Should be chosen uniquely for all clusters of a customer at the very least
        so that they can use all of their clusters at the same time without having
        to tear down tunnels.
      '';
      type = types.nullOr types.nonEmptyStr;
      default = null;
      example = "fd01::1/120";
    };
    endpoints = mkOption {
      description = ''
        Defines a WireGuard endpoint/server.
        To allow rolling key rotations, multiple endpoints can be added.
        Each endpoint's id, port and subnet need to be unique.
      '';
      default = [];
      type = types.listOf (types.submodule {
        options = {
          enabled = mkOption {
            description = ''
              Whether this endpoint is enabled on the frontend nodes.
            '';
            type = types.bool;
            default = true;
          };
          id = mkOption {
            description = ''
              An ID unique to this endpoint
            '';
            type = with types; either ints.unsigned nonEmptyStr;
            apply = toString; # JSON/YAML/TOML only allow strings as keys
            example = 0;
          };
          port = mkOption {
            description = ''
              The port Wireguard should use on the frontend nodes
            '';
            type = types.port;
            default = 7777;
          };
          ip_cidr = mkOption {
            description = ''
              IP address range to use for WireGuard clients. Must be set to a CIDR and must
              not conflict with the terraform.subnet_cidr.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = ipv4Cidr;
          };
          ip_gw = mkOption {
            description = ''
              IP address range to use for WireGuard servers. Must be set to a CIDR and must
              not conflict with the terraform.subnet_cidr.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = ipv4Cidr;
          };
          ipv6_cidr = mkOption {
            description = ''
              IP address range to use for WireGuard clients. Must be set to a CIDR and must
              not conflict with the terraform.subnet_cidr.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = types.nullOr types.nonEmptyStr;
            default = null;
            example = "fd01::/120";
          };
          ipv6_gw = mkOption {
            description = ''
              IP address range to use for WireGuard servers. Must be set to a CIDR and must
              not conflict with the terraform.subnet_cidr.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = types.nullOr types.nonEmptyStr;
            default = null;
            example = "fd01::1/120";
          };
        };
      });
    };
    peers = mkOption {
      description = ''
        The Wireguard peers that should be able to connect to the frontend nodes.
      '';
      default = [];
      type = types.listOf (types.submodule {
        options = {
          pub_key = mkOption {
            description = ''
              The public key of the peer created with `wg keygen`
            '';
            type = types.nonEmptyStr;
          };
          ident = mkOption {
            description = ''
              An identifier for the public key
            '';
            type = types.nonEmptyStr;
            example = "name.lastname";
          };
          ip = mkOption {
            type = with types; nullOr (either ipv4Cidr ipv4Addr);
            default = null;
          };
          ips = mkOption {
            type = with types; attrsOf (either ipv4Cidr ipv4Addr);
            default = {};
          };
          ipv6 = mkOption {
            type = types.nullOr types.nonEmptyStr;
            default = null;
          };
          ipsv6 = mkOption {
            type = types.attrsOf types.nonEmptyStr;
            default = {};
          };
        };
      });
    };
  };
  config.yk8s = let
    legacy_options = ["port" "ip_gw" "ip_cidr" "ipv6_gw" "ipv6_cidr"];
    ansible_prefix = "wg_";
    inventory_path = "gateways/wireguard.yaml";
    transformations = [
      removeObsoleteOptions
      filterInternal
      (filterAttrs (name: _: ! elem name legacy_options))
      filterNull
    ];
    wireguard_helper = mkDerivation rec {
      name = "yaook-k8s-wireguard-helper";
      src = ./.;

      nativeBuildInputs = [pkgs.makeWrapper];
      buildInputs = [
        (pkgs.python3.withPackages (ps:
          with ps; [
            toml
            pyyaml
          ]))
      ];
      buildPhase = ''
        install -m 755 -D $src/wireguard_helper.py $out/bin/wireguard_helper
      '';
      postInstall = ''
        wrapProgram $out/bin/wireguard_helper  \
          --prefix PATH : ${lib.makeBinPath buildInputs}
      '';
    };
    varsFile = (pkgs.formats.json {}).generate "wireguard.json" (pipe cfg transformations);
    ipam_path = "wireguard/ipam.toml";
    wireguard_helper_output = let
      current_ipam_file =
        if config.yk8s.state_directory != null
        then "${config.yk8s.state_directory}/${ipam_path}"
        else "";
    in
      pkgs.runCommandLocal "wireguard_helper_output" {} ''
        mkdir -p $(dirname $out/${ipam_path})
        if [ -e "${current_ipam_file}" ]; then
          install -m644 -D ${current_ipam_file} $out/${ipam_path}
        fi
        export WG_IPAM_CONFIG_PATH=$out/${ipam_path}
        export WG_PREFIX=${ansible_prefix}
        ${wireguard_helper}/bin/wireguard_helper ${varsFile} $out/${inventory_path}
      '';
  in {
    _inventory_packages = [(linkToPath "${wireguard_helper_output}/${inventory_path}" "group_vars/${inventory_path}")];
    _state_packages = [(linkToPath "${wireguard_helper_output}/${ipam_path}" ipam_path)];
    wireguard.endpoints =
      if cfg.port != null
      then [
        {
          id = 0;
          inherit (cfg) port ip_cidr ip_gw ipv6_cidr ipv6_gw;
        }
      ]
      else [];
    warnings = builtins.foldl' (
      acc: opt: acc ++ lib.optional ((builtins.getAttr opt cfg) != null) "${opt} is deprecated. Use endpoints instead."
    ) [] ["port" "ip_cidr" "ip_gw" "ipv6_cidr" "ipv6_gw"];
    assertions = let
      inherit (builtins) length;
      inherit (lib.lists) unique;
      allUnique = l: (length (unique l)) == length l;
    in [
      {
        assertion = cfg.enabled -> (length cfg.endpoints) != 0;
        message = "Wireguard is enabled but no endpoints are configured.";
      }
      {
        assertion = cfg.enabled -> (length cfg.peers) != 0;
        message = "Wireguard is enabled but no peers are configured.";
      }
      {
        assertion = cfg.enabled -> allUnique (map (p: p.ident) cfg.peers);
        message = "wireguard.peers.[].ident are not unique";
      }
      {
        assertion = cfg.enabled -> allUnique (map (p: p.pub_key) cfg.peers);
        message = "wireguard.peers.[].pub_key are not unique";
      }
      {
        assertion = cfg.enabled -> allUnique (map (p: p.id) cfg.endpoints);
        message = "wireguard.endpoints.[].id are not unique";
      }
    ];
  };
}
