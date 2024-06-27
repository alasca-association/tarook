{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.ch-k8s-lbaas;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedResourceOptionModules mkResourceOptionModule;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkResourceOption;
  inherit (yk8s-lib.types) ipv4Addr;
in {
  imports =
    mkRenamedResourceOptionModules "ch-k8s-lbaas" ["controller"]
    ++ [
      (mkResourceOptionModule "ch-k8s-lbaas" "controller_resources" {
        description = "Request and limit for the LBaaS controller";
        cpu.request = "100m";
        memory.limit = "256Mi";
      })
    ];

  options.yk8s.ch-k8s-lbaas = mkTopSection {
    _docs.preface = ''
      .. _cluster-configuration.ch-k8s-lbaas:

      LBaaS Configuration
      ^^^^^^^^^^^^^^^^^^^
    '';
    enabled = mkEnableOption "our LBaas service";
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
      default = "0.9.0";
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

        * openstack: Uses OpenStack and the yaook/k8s gateway nodes to provision
          LBaaS IP addresses ports.
        * static: Uses a fixed set of IP addresses to use for load balancing. When the
          static port manager is used, the ``agent_urls`` and ``static_ipv4_addresses``
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
      apply = v:
        if v == [] && cfg.port_manager == "static"
        then throw "[ch-k8s-lbaas] port_manager is 'static' but static_ipv4_addresses is empty"
        else v;
    };
    agent_urls = mkOption {
      description = ''
        Customize URLs for the agents. This will typically be a list of HTTP URLs
        like http://agent_ip:15203. This option is only used if the port manager is
        set to `static`, and must be set if the port manager is `static`.
      '';
      default = [];
      type = types.listOf types.str;
      apply = v:
        if v == [] && cfg.port_manager == "static"
        then throw "[ch-k8s-lbaas] port_manager is 'static' but agent_urls is empty"
        else v;
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "ch_k8s_lbaas_";
      inventory_path = "all/ch-k8s-lbaas.yaml";
      only_if_enabled = true;
    })
  ];
}
