{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.wireguard;
  inherit (lib) mkOption types;
  inherit (config.yk8s._lib) mkInternalOption;

  endpointModule = types.submodule {
    enabled = mkOption {
      description = ''
        Whether this endpoint is enabled on the frontend nodes.
      '';
      type = types.bool;
      default = true;
    };
    id = mkOption {
      description = ''
        A numeric ID unique to this endpoint
      '';
      type = types.int;
      example = ''
        id = 0;
      '';
    };
    port = mkOption {
      description = ''
        The port Wireguard should use on the frontend nodes
      '';
      type = types.int;
      example = ''
        port = 7777;
      '';
    };
  };
  # peerModule =
in {
  options.yk8s.wireguard = {
    endpoints = mkOption {
      description = ''
        Defines a WireGuard endpoint/server.
        To allow rolling key rotations, multiple endpoints can be added.
        Each endpoint's id, port and subnet need to be unique.
      '';
      type = types.listOf endpointModule;
      default = [];
    };
    _ansible_prefix = mkInternalOption {
      type = types.str;
      default = "wg_";
    };
    _inventory_path = mkInternalOption {
      type = types.str;
      default = "gateways/wireguard.yaml";
    };
  };
  config = {
  };
}
