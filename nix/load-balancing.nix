{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s."load-balancing";
  inherit (lib) mkOption mkEnableOption types;
  inherit (config.yk8s._lib) mkInternalOption;
in {
  options.yk8s."load-balancing" = {
    lb_ports = mkOption {
      description = ''
        lb_ports is a list of ports that are exposed by HAProxy on the gateway nodes and forwarded
        to NodePorts in the k8s cluster. This poor man's load-balancing / exposing of services
        has been superseded by ch-k8s-lbaas. For legacy reasons and because it's useful under
        certain circumstances it is kept inside the repository.
        The NodePorts are either literally exposed by HAProxy or can be mapped to other ports.
        The `layer` attribute can either be `tcp` (L4) or `http` (L7). For `http`, `option forwardfor`
        is added implicitly to the backend servers in the haproxy configuration.
        If `use_proxy_protocol` is set to `true`, HAProxy will use the proxy protocol to convey information
        about the connection initiator to the backend. NOTE: the backend has to accept the proxy
        protocol, otherwise your traffic will be discarded.
      '';
      example = ''
        Short form: [30060];
        Explicit form: [{external=80,nodeport=30080, layer=tcp, use_proxy_protocol=true}]
      '';
      default = [];
      type = types.listOf types.int; # TODO: support for explicit form
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
    openstack_lbaas = mkEnableOption "Enable/Disable OpenStack-based load-balancing";

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
    };
    _ansible_prefix = mkInternalOption {
      type = types.str;
      default = "";
    };
    _inventory_path = mkInternalOption {
      type = types.str;
      default = "all/load-balancing.yaml";
    };
  };
  config = {
    # TODO:
    # for host in config.get("load-balancing", {}).get("priorities", {}).keys():
    #     print(
    #         "WARNING: ignoring deprecated host-based priority override for "
    #         "host {}".format(host)
    #     )
  };
}
