{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.wireguard;
  inherit (lib) mkOption types;
  inherit (config.yk8s._lib) mkInternalOption;
in {
  options.yk8s.wireguard = {
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
          ip_cidr = mkOption {
            description = ''
              IP address range to use for WireGuard clients. Must be set to a CIDR and must
              not conflict with the terraform.subnet_cidr.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = types.str;
            default = "172.30.153.64/26";
          };
          ip_gw = mkOption {
            description = ''
              IP address range to use for WireGuard servers. Must be set to a CIDR and must
              not conflict with the terraform.subnet_cidr.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = types.str;
            default = "172.30.153.65/26";
          };
          ipv6_cidr = mkOption {
            description = ''
              IP address range to use for WireGuard clients. Must be set to a CIDR and must
              not conflict with the terraform.subnet_cidr.
              Should be chosen uniquely for all clusters of a customer at the very least
              so that they can use all of their clusters at the same time without having
              to tear down tunnels.
            '';
            type = with types; nullOr str;
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
            type = with types; nullOr str;
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
            type = types.str;
          };
          ident = mkOption {
            description = ''
              An identifier for the public key
            '';
            type = types.str;
            example = "name.lastname";
          };
        };
      });
    };
    # TODO: legacy options
    # TODO: integrate wireguard_helper
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
