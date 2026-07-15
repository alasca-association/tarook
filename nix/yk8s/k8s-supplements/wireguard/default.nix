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
  inherit (lib) mkOption;
  inherit (lib.attrsets) filterAttrs;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkJson types;
  inherit (yk8s-lib) linkToPath;
  inherit
    (yk8s-lib.transform)
    filterInternal
    removeObsoleteOptions
    ;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (builtins) foldl' elem fromJSON readFile toString;
  inherit (lib.trivial) pipe;
in {
  imports = [
    (mkRenamedOptionModule ["wireguard" "wg_ip_cidr"] ["wireguard" "ip_cidr"])
    (mkRenamedOptionModule ["wireguard" "wg_ipv6_cidr"] ["wireguard" "ipv6_cidr"])
    (mkRemovedOptionModule ["wireguard" "rollout_company_users"] "")
    (mkRemovedOptionModule ["wireguard" "s2s_enabled"] "")
    (mkRemovedOptionModule ["wireguard" "port"] "Use endpoints instead")
    (mkRemovedOptionModule ["wireguard" "ip_cidr"] "Use endpoints instead")
    (mkRemovedOptionModule ["wireguard" "ipv6_cidr"] "Use endpoints instead")
    (mkRemovedOptionModule ["wireguard" "ip_gw"] "Use endpoints instead")
    (mkRemovedOptionModule ["wireguard" "ipv6_gw"] "Use endpoints instead")
  ];

  options.yk8s.wireguard = mkTopSection {
    _docs.preface = ''
      .. note:: Wireguard is currently only supported on gateway nodes.

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
            type = types.ints.unsigned;
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
              not conflict with the :ref:`configuration-options.yk8s.infra.subnet_cidr`.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = types.yk8s.networking.ipv4Cidr;
          };
          ip_gw = mkOption {
            description = ''
              IP address range to use for WireGuard servers. Must be set to a CIDR and must
              not conflict with the :ref:`configuration-options.yk8s.infra.subnet_cidr`.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = types.yk8s.networking.ipv4Cidr;
          };
          ipv6_cidr = mkOption {
            description = ''
              IP address range to use for WireGuard clients. Must be set to a CIDR and must
              not conflict with the :ref:`configuration-options.yk8s.infra.subnet_cidr`.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = with types; nullOr yk8s.networking.ipv6Cidr;
            default = null;
            example = "fd01::/120";
          };
          ipv6_gw = mkOption {
            description = ''
              IP address range to use for WireGuard servers. Must be set to a CIDR and must
              not conflict with the :ref:`configuration-options.yk8s.infra.subnet_cidr`.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = with types; nullOr yk8s.networking.ipv6Cidr;
            default = null;
            example = "fd01::1/120";
          };
        };
      });
    };
    peers = mkOption {
      description = ''
        The Wireguard peers that should be able to connect to the frontend nodes.

        The orchestrator must be included in this list.
      '';
      default = [];
      example = [
        {
          ident = "alice";
          pub_key = "ExampleWgKeyLiKUsKjhSDY9u06pX68rbdg4V6dkHFo=";
        }
        {
          ident = "bob";
          pub_key = "AnotherExampleWgKey8xOMMOW2dsda6s6BKkasi3al=";
        }
      ];
      type = types.listOf (types.submodule {
        options = {
          pub_key = mkOption {
            description = ''
              The public key of the peer created with `wg keygen`
            '';
            type = types.yk8s.wireguard.key;
          };
          ident = mkOption {
            description = ''
              An identifier for the public key
            '';
            # NOTE: ident is used as part of a filename
            type = types.yk8s.posix.filename;
            example = "name.lastname";
          };
          ip = mkOption {
            type = with types; nullOr yk8s.networking.ipv4Addr;
            default = null;
          };
          ips = mkOption {
            type = with types; attrsOf (either yk8s.networking.ipv4Cidr yk8s.networking.ipv4Addr);
            default = {};
          };
          ipv6 = mkOption {
            type = with types; nullOr yk8s.networking.ipv6Addr;
            default = null;
          };
          ipsv6 = mkOption {
            type = with types; attrsOf (either yk8s.networking.ipv6Cidr yk8s.networking.ipv6Addr);
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
    varsFile = mkJson "wireguard.json" (pipe cfg transformations);
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
    _targets.ansible.inventory_packages =
      if cfg.enabled
      then [(linkToPath "${wireguard_helper_output}/${inventory_path}" "group_vars/${inventory_path}")]
      else [
        (mkGroupVarsFile {
          cfg = {"${ansible_prefix}enabled" = false;};
          inherit inventory_path;
        })
      ];
    _targets.ansible.state_packages = lib.lists.optional cfg.enabled (linkToPath "${wireguard_helper_output}/${ipam_path}" ipam_path);
    _targets.ansible.warnings =
      []
      ++ lib.optional (cfg.enabled && (builtins.length cfg.peers) == 0)
      "config.yk8s.wireguard.peers: is empty"
      ++ lib.pipe cfg.endpoints [
        # enumerate endpoints
        (lib.imap0 (index: endpoint: {inherit index endpoint;}))
        (lib.filter (x: x.endpoint.port == 0))
        (lib.map (x: "config.yk8s.wireguard.endpoints[${toString (x.index)}].port: should not be port zero"))
      ];
    _targets.ansible.assertions = let
      inherit (builtins) length;
      inherit (lib.lists) unique;
      allUnique = l: (length (unique l)) == length l;
    in [
      {
        assertion = cfg.enabled -> (length (lib.attrNames config.yk8s.infra.final_hosts.gateways.hosts)) != 0;
        message = lib.concatStrings [
          "config.yk8s.wireguard.enabled:"
          " cannot be true when no gateway nodes are configured."
          " Wireguard is currently only supported in combination with a gateway-plane."
        ];
      }
      {
        assertion = cfg.enabled -> (length cfg.endpoints) != 0;
        message = "config.yk8s.wireguard.endpoints: must not be empty";
      }
      {
        assertion = cfg.enabled -> allUnique (map (p: p.ident) cfg.peers);
        message = "config.yk8s.wireguard.peers.[].ident: must be unique";
      }
      {
        assertion = cfg.enabled -> allUnique (map (p: p.pub_key) cfg.peers);
        message = "config.yk8s.wireguard.peers.[].pub_key: must be unique";
      }
      {
        assertion = cfg.enabled -> allUnique (map (p: p.id) cfg.endpoints);
        message = "config.yk8s.wireguard.endpoints.[].id: must be unique";
      }
      {
        assertion = cfg.enabled -> allUnique (map (p: p.port) cfg.endpoints);
        message = "config.yk8s.wireguard.endpoints.[].port: must be unique";
      }
      {
        # 636 = 576 (reasonable minimum MTU for IPv4) + 20 (IPv4 Header) + 8 (UDP Header) + 32 (Wireguard Header)
        assertion = cfg.enabled && config.yk8s.infra.ipv4_enabled && config.yk8s.openstack.enabled -> config.yk8s.openstack.network_mtu >= 636;
        message = "config.yk8s.openstack.network_mtu: must be at least 636 Bytes to support Wireguard on IPv4";
      }
      {
        # 1360 = 1280 (technical minimum MTU for IPv6) + 40 (IPv6 Header) + 8 (UDP Header) + 32 (Wireguard Header)
        assertion = cfg.enabled && config.yk8s.infra.ipv6_enabled && config.yk8s.openstack.enabled -> config.yk8s.openstack.network_mtu >= 1360;
        message = "config.yk8s.openstack.network_mtu: must be at least 1360 Bytes to support Wireguard on IPv6";
      }
    ];
  };
}
