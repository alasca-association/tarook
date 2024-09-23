{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.ipsec;
  modules-lib = import ../../../../nix/yk8s/lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
in {
  imports = [
    (mkRemovedOptionModule "ipsec" "eap_psk" "")
  ];

  options.yk8s.ipsec = mkTopSection {
    _docs.preface = ''
      IPsec Configuration
      ^^^^^^^^^^^^^^^^^^^

      More details about the IPsec setup can be found
      :doc:`here </user/explanation/vpn/ipsec>`.
    '';

    enabled = mkEnableOption "";
    purge_installation = mkEnableOption "purging the ipsec installation";
    remote_name = mkOption {
      type = types.str;
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
      type = with types; listOf str;
    };
    esp_proposals = mkOption {
      description = ''
        A list of parent SA proposals to offer to the client.
      '';
      type = with types; listOf str;
      default = cfg.proposals;
      defaultText = "\${cfg.proposals}";
    };
    peer_networks = mkOption {
      description = ''
        List of CIDRs to route to the peer. If not set, only dynamic IP
        assignments will be routed.
      '';
      type = with types; listOf str;
      default = [];
    };

    local_networks = mkOption {
      description = ''
        List of CIDRs to offer to the peer
      '';
      type = with types; listOf str;
      default = [config.yk8s.terraform.subnet_cidr];
      example = ''
        Set the following for a working NAT-free setup
        [
          config.yk8s.terraform.subnet_cidr
          config.yk8s.kubernetes.network.pod_subnet
          config.yk8s.kubernetes.network.service_subnet
        ]
      '';
    };
    virtual_subnet_pool = mkOption {
      description = ''
        Pool to source virtual IP addresses from. Those are the IP addresses assigned
        to clients which do not have remote networks. (e.g.: "10.3.0.0/24")
      '';
      type = with types; nullOr str;
      default = null;
    };
    remote_addrs = mkOption {
      description = ''
        List of addresses to accept as remote. When initiating, the first single IP
        address is used.
      '';
      type = with types; listOf str;
      default = []; # TODO conflicting values: role has false
    };
    remote_private_addrs = mkOption {
      description = ''
        Private address of remote endpoint.
        only used when test_enabled is True
      '';
      type = types.str; # TODO: or listOf str ?
      default = "";
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "ipsec_";
      inventory_path = "all/ipsec.yaml";
      only_if_enabled = true;
    })
  ];
}
