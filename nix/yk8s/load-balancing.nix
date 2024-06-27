{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.load-balancing;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;

  explicitPorts = types.submodule {
    options = {
      external = mkOption {
        description = ''
          The port that is available externally
        '';
        type = types.port;
      };
      nodeport = mkOption {
        description = ''
          The local port to which the external port is going to be mapped
        '';
        type = types.port;
      };
      layer = mkOption {
        description = ''
          The `layer` attribute can either be `tcp` (L4) or `http` (L7). For `http`, `option forwardfor`
          is added implicitly to the backend servers in the haproxy configuration.
        '';
        type = types.strMatching "tcp|http";
        default = "tcp";
      };
      use_proxy_protocol = mkOption {
        description = ''
          If `use_proxy_protocol` is set to `true`, HAProxy will use the proxy protocol to convey information
          about the connection initiator to the backend. NOTE: the backend has to accept the proxy
          protocol, otherwise your traffic will be discarded.
        '';
        type = types.bool;
        default = false;
      };
    };
  };
in {
  options.yk8s.load-balancing = mkTopSection {
    _docs.order = 2;
    _docs.preface = ''
      .. _cluster-configuration.configuring-load-balancing:

      Configuring Load-Balancing
      ^^^^^^^^^^^^^^^^^^^^^^^^^^

      By default, if you’re deploying on top of OpenStack, the self-developed
      load-balancing solution :doc:`ch-k8s-lbaas </user/explanation/services/ch-k8s-lbaas>`
      will be used to avoid the aches of using OpenStack Octavia. Nonetheless,
      you are not forced to use it and can easily disable it.

      The following section contains legacy load-balancing options which will
      probably be removed in the foreseeable future.
    '';

    lb_ports = mkOption {
      description = ''
        lb_ports is a list of ports that are exposed by HAProxy on the gateway nodes and forwarded
        to NodePorts in the k8s cluster. This poor man's load-balancing / exposing of services
        has been superseded by ch-k8s-lbaas. For legacy reasons and because it's useful under
        certain circumstances it is kept inside the repository.
        The NodePorts are either literally exposed by HAProxy or can be mapped to other ports.
      '';
      example = ''
        Short form: [30060];
        Explicit form: [{external=80,nodeport=30080, layer=tcp, use_proxy_protocol=true}]
      '';
      default = [];
      type = with types; listOf (either port explicitPorts);
    };

    deprecated_nodeport_lb_test_port = mkOption {
      type = types.port;
      default = 0; # TODO or null?
    };

    vrrp_priorities = mkOption {
      description = ''
        A list of priorities to assign to the gateway/frontend nodes. The priorities
        will be assigned based on the sorted list of matching nodes.

        If more nodes exist than there are entries in this list, the rollout will
        fail.

        Please note the keepalived.conf manpage for choosing priority values.
      '';
      type = types.listOf types.int;
      default = [150 100 50];
    };
    openstack_lbaas = mkEnableOption "OpenStack-based load-balancing";

    haproxy_stats_port = mkOption {
      description = ''
        Port for HAProxy statistics
      '';
      type = types.int;
      default = 48981;
    };
    priorities = mkOption {
      description = ''
        Deprecated
      '';
      type = types.listOf types.str;
      default = [];
      apply = builtins.map (host: "[load-balancer.priority] ignoring deprecated host-based priority override for host ${host}"); # TODO why not simple remove that option?
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/load-balancing.yaml";
    })
  ];
}
