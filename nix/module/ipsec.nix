{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.ipsec;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.ipsec = mkTopSection {
    enabled = mkEnableOption "";
    test_enabled = mkEnableOption ''
      Flag to enable the test suite.
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
    };
virtual_subnet_pool = mkOption {
  description = ''
    Pool to source virtual IP addresses from. Those are the IP addresses assigned
    to clients which do not have remote networks. (e.g.: "10.3.0.0/24")
  '';
  type = with types; nullOr str; # TODO or listOf str ? 
  default = null;
};
remote_addr = mkOption {
  description = ''
    List of addresses to accept as remote. When initiating, the first single IP
    address is used.
  '';
  type = with types; listOf str;
  default = [];
};
remote_private_addrs = mkOption {
  description = ''
    Private address of remote endpoint.
    only used when test_enabled is True
  '';
  type = types.str; # TODO: or listOf str ?
  default = ""; 
};
eap_psk = mkOption {
  description = ''
    The PSK for EAP
  '';
  type = types.str;
};



  };
  config.yk8s.ipsec = {
    _ansible_prefix = "ipsec_";
    _inventory_path = "all/ipsec.yaml";
    _only_if_enabled = true;
  };
}
