{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.network;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkSubSection;
  inherit
    (yk8s-lib.types)
    ipv4Cidr
    ipv6Cidr
    privateUseAutonomousSystemNumber
    ;
in {
  imports = [
    (mkRemovedOptionModule ["kubernetes" "network" "plugin_switch_restart_all_namespaces"] "")
    (mkRemovedOptionModule ["kubernetes" "network" "plugin"] "CNIs use their own enable options instead, eg. kubernetes.network.calico.enabled")
  ];
  options.yk8s.kubernetes.network = mkSubSection {
    _docs.order = 8;

    pod_subnet = mkOption {
      description = ''
        This is the IPv4 subnet used by Kubernetes for Pods. Subnets will be delegated
        automatically to each node.
      '';
      default = "10.244.0.0/16";
      type = ipv4Cidr;
    };
    service_subnet = mkOption {
      description = ''
        This is the IPv4 subnet used by Kubernetes for Services.
      '';
      default = "10.96.0.0/12";
      type = ipv4Cidr;
    };
    pod_subnet_v6 = mkOption {
      description = ''
        This is the IPv6 subnet used by Kubernetes for Pods. Subnets will be delegated
        automatically to each node.
      '';
      default = "fdff:2::/56";
      type = ipv6Cidr;
    };
    service_subnet_v6 = mkOption {
      description = ''
        This is the IPv6 subnet used by Kubernetes for Services.

        The service subnet is bounded; for 128-bit addresses, the mask must be >= 108
        The service cluster IP range is validated by the kube-apiserver to have at most 20 host bits
        https://github.com/kubernetes/kubernetes/blob/v1.9.2/cmd/kube-apiserver/app/options/validation.go#L29-L32
        https://github.com/kubernetes/kubernetes/pull/12841

      '';
      default = "fdff:3::/108";
      type = ipv6Cidr;
    };

    bgp_announce_service_ips = mkEnableOption ''
      announcement of the service cluster IP range to external
      BGP peers. By default, only per-node pod networks are announced.
    '';

    bgp_worker_as = mkOption {
      type = privateUseAutonomousSystemNumber;
      default = 64512;
    };

    bgp_gateway_as = mkOption {
      type = privateUseAutonomousSystemNumber;
      default = 65000;
    };

    ipv4_nat_outgoing = mkOption {
      description = ''
        Enable outgoing IPv4 network address translation
      '';
      type = types.bool;
      default = true;
    };
    ipv6_nat_outgoing = mkOption {
      description = ''
        Enable outgoing IPv6 network address translation
      '';
      type = types.bool;
      default = false;
    };
  };
}
