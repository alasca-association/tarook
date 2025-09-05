{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.ipsec;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
  inherit (yk8s-lib.transform) ignoreItemsOfDisabledIPFamily;
in {
  imports = [
    (mkRemovedOptionModule "ipsec" "eap_psk" "")
  ];

  options.yk8s.ipsec = mkTopSection {
    _docs.preface = ''
      More details about the IPsec setup can be found
      :doc:`here </user/explanation/vpn/ipsec>`.
    '';

    enabled = mkEnableOption "IPsec";
    purge_installation = mkEnableOption "purging the IPsec installation";
    remote_name = mkOption {
      # TODO: type as per https://docs.strongswan.org/docs/latest/swanctl/swanctlConf.html#_connections_conn_local field 'id'
      type = types.nonEmptyStr;
      default = "peerid";
    };
    test_enabled = mkEnableOption ''
      the test suite.
      Must make sure a remote endpoint, with ipsec enabled, is running and open for connections.
    '';
    proposals = mkOption {
      description = ''
        A list of parent SA proposals to offer to the client.
      '';
      type = with types; listOf types.yk8s.networking.ipsecProposalStr;
    };
    esp_proposals = mkOption {
      description = ''
        A list of parent SA proposals to offer to the client.
      '';
      type = with types; listOf types.yk8s.networking.ipsecProposalStr;
      default = cfg.proposals;
      defaultText = "\${cfg.proposals}";
    };
    peer_networks = mkOption {
      description = ''
        List of CIDRs to route to the peer. If not set, only dynamic IP
        assignments will be routed.
      '';
      type = with types; listOf (either types.yk8s.networking.ipv4Cidr types.yk8s.networking.ipv6Cidr);
      default = [];
      apply = v:
        ignoreItemsOfDisabledIPFamily {
          ipv4Types = [types.yk8s.networking.ipv4Cidr];
          ipv6Types = [types.yk8s.networking.ipv6Cidr];
          ipv4Enabled = config.yk8s.infra.ipv4_enabled;
          ipv6Enabled = config.yk8s.infra.ipv6_enabled;
        }
        "config.yk8s.ipsec.peer_networks: "
        v;
    };

    local_networks = mkOption {
      description = ''
        List of CIDRs to offer to the peer
      '';
      type = with types; listOf (either types.yk8s.networking.ipv4Cidr types.yk8s.networking.ipv6Cidr);
      default = [config.yk8s.infra.subnet_cidr];
      example = ''
        Set the following for a working NAT-free setup
        [
          config.yk8s.infra.subnet_cidr
          config.yk8s.kubernetes.network.pod_subnet
          config.yk8s.kubernetes.network.service_subnet
        ]
      '';
      apply = v:
        ignoreItemsOfDisabledIPFamily {
          ipv4Types = [types.yk8s.networking.ipv4Cidr];
          ipv6Types = [types.yk8s.networking.ipv6Cidr];
          ipv4Enabled = config.yk8s.infra.ipv4_enabled;
          ipv6Enabled = config.yk8s.infra.ipv6_enabled;
        }
        "config.yk8s.ipsec.local_networks: "
        v;
    };
    virtual_subnet_pool = mkOption {
      description = ''
        Pool to source virtual IP addresses from. Those are the IP addresses assigned
        to clients which do not have remote networks. (e.g.: "10.3.0.0/24")
      '';
      type = with types; nullOr (listOf (either types.yk8s.networking.ipv4Cidr types.yk8s.networking.ipv6Cidr));
      default = null;
      apply = v:
        if v == null
        then v
        else
          (
            ignoreItemsOfDisabledIPFamily {
              ipv4Types = [types.yk8s.networking.ipv4Cidr];
              ipv6Types = [types.yk8s.networking.ipv6Cidr];
              ipv4Enabled = config.yk8s.infra.ipv4_enabled;
              ipv6Enabled = config.yk8s.infra.ipv6_enabled;
            }
            "config.yk8s.ipsec.virtual_subnet_pool: "
            v
          );
    };
    remote_addrs = mkOption {
      description = ''
        List of addresses to accept as remote. When initiating, the first single IP
        address is used.
      '';
      type = with types; listOf (either types.yk8s.networking.ipv4Addr types.yk8s.networking.ipv6Addr);
      default = [];
      apply = v:
        ignoreItemsOfDisabledIPFamily {
          ipv4Types = [types.yk8s.networking.ipv4Addr];
          ipv6Types = [types.yk8s.networking.ipv6Addr];
          ipv4Enabled = config.yk8s.infra.ipv4_enabled;
          ipv6Enabled = config.yk8s.infra.ipv6_enabled;
        }
        "config.yk8s.ipsec.remote_addrs: "
        v;
    };
    remote_private_addrs = mkOption {
      description = ''
        Private address of remote endpoints.
        only used when :ref:`configuration-options.yk8s.ipsec.test_enabled` is ``true``
      '';
      type = with types; nullOr (listOf (either types.yk8s.networking.ipv4Addr types.yk8s.networking.ipv6Addr));
      default = null;
      apply = v:
        ignoreItemsOfDisabledIPFamily {
          ipv4Types = [types.yk8s.networking.ipv4Addr];
          ipv6Types = [types.yk8s.networking.ipv6Addr];
          ipv4Enabled = config.yk8s.infra.ipv4_enabled;
          ipv6Enabled = config.yk8s.infra.ipv6_enabled;
        }
        "config.yk8s.ipsec.remote_private_addrs: "
        v;
    };
  };
  config.yk8s.assertions = [
    {
      assertion = cfg.test_enabled -> (cfg.remote_private_addrs != null);
      message = "config.yk8s.ipsec.remote_private_addrs: must be set because config.yk8s.ipsec.test_enabled=true";
    }
  ];
  config.yk8s.warnings = lib.optional (cfg.enabled) "config.yk8s.ipsec: is deprecated. Support for it will be dropped in a release after v11.0.0";
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "ipsec_";
      inventory_path = "all/ipsec.yaml";
      only_if_enabled = true;
    })
  ];
}
