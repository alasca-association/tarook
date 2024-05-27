{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.ch-k8s-lbaas;
  inherit (lib) mkOption mkEnableOption types;
  inherit (config.yk8s._lib) mkTopSection;

  ipv4Addr = types.strMatching "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$";
in {
  options.yk8s.ch-k8s-lbaas = mkTopSection {
    enabled = mkEnableOption "Enable out LBaas service";
    shared_secret = mkOption {
      description = ''
        A unique, random, base64-encoded secret.
        To generate such a secret, you can use the following command:
        $ dd if=/dev/urandom bs=16 count=1 status=none | base64
      '';
      type = types.str;
      example = "RuDXD7CcNZHrRAV9AAN83T7Hc6wVk9IGzPou6UjwWhL+4hu1I4XPj+YG/AgKiFIc1a1EzmQKax9VAj6P/oA45w==";
    };
    version = mkOption {
      type = types.str;
      default = "0.7.0";
    };
    agent_port = mkOption {
      description = ''
        The TCP port on which the LBaaS agent should listen on the frontend nodes.
      '';
      type = types.port;
      default = 15203;
    };
    port_manager = mkOption {
      description = ''
        Configure which IP address ("port") manager to use. Two options are available:
        - openstack: Uses OpenStack and the yaook/k8s gateway nodes to provision
          LBaaS IP addresses ports.
        - static: Uses a fixed set of IP addresses to use for load balancing. When the
          static port manager is used, the `agent_urls` and `static_ipv4_addresses`
          options must also be configured.
      '';
      type = types.strMatching "openstack|static";
      default = "openstack";
    };
    static_ipv4_addresses = mkOption {
      description = ''
        List of IPv4 addresses which are usable for the static port manager. It is
        your responsibility to ensure that the node(s) which run the agent(s) receive
        traffic for these IPv4 addresses.
      '';
      default = [];
      type = types.listOf ipv4Addr;
    };
    agent_urls = mkOption {
      description = ''
        Customize URLs for the agents. This will typically be a list of HTTP URLs
        like http://agent_ip:15203. This option is only used if the port manager is
        set to `static`, and must be set if the port manager is `static`.
      '';
      type = types.listOf types.str;
    };
    controller_cpu_request = mkOption {
      description = "CPU resources request for the lbaas controller";
      type = types.nullOr types.str;
      default = null;
      example = "100m";
    };
    controller_memory_limit = mkOption {
      description = ''
        Memory resources limit for the lbaas controller
      '';
      type = types.nullOr types.str;
      default = null;
      example = "256Mi";
    };
  };
  config.yk8s.ch-k8s-lbaas = {
    # TODO: I'm not exposing CPU limits and memory requests here for now
    _ansible_prefix = "ch_k8s_lbaas";
    _inventory_path = "all/ch-k8s-lbaas.yaml";
    _only_if_enabled = true;
  };
  # TODO: verify static_ipv4_addresses and agent_urls are set if port_manager  = "static"
  # TODO: only evaluate if enabled = true
  # TODO: what to do about requests = null?
}
