{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.network;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (lib) mkOption mkEnableOption;
  inherit (yk8s-lib) mkSubSection types mkDisableOption mkInternalOption;
in {
  imports = [
    (mkRemovedOptionModule ["kubernetes" "network" "plugin_switch_restart_all_namespaces"] "")
    (mkRemovedOptionModule ["kubernetes" "network" "plugin"] "CNIs use their own enable options instead, eg. kubernetes.network.calico.enabled")
  ];
  options.yk8s.kubernetes.network = mkSubSection {
    _docs.order = 8;

    kube_proxy = {
      enabled = mkDisableOption ''
        kube-proxy. Disable if you want to use a eBPF dataplane
      '';
      mode = mkOption {
        description = ''
          Which proxy mode to use. Note that ``ipvs`` mode is deprecated.
        '';
        type = types.enum ["iptables" "nftables" "ipvs"];
        default =
          if config.yk8s.infra.ipv6_enabled
          then "ipvs"
          else "iptables";
        defaultText = lib.literalExpression ''
          if config.yk8s.infra.ipv6_enabled then "ipvs" else "iptables"
        '';
      };

      kubeProxyConfiguration = mkOption {
        type = types.yk8s.formats.jsonValue;
      };
    };

    pod_subnet = mkOption {
      description = ''
        This is the IPv4 subnet used by Kubernetes for Pods. Subnets will be delegated
        automatically to each node.
      '';
      default = "10.244.0.0/16";
      type = types.yk8s.networking.ipv4Cidr;
    };
    service_subnet = mkOption {
      description = ''
        This is the IPv4 subnet used by Kubernetes for Services.
      '';
      default = "10.96.0.0/12";
      type = types.yk8s.networking.ipv4Cidr;
    };
    pod_subnet_v6 = mkOption {
      description = ''
        This is the IPv6 subnet used by Kubernetes for Pods. Subnets will be delegated
        automatically to each node.
      '';
      default = "fdff:2::/56";
      type = types.yk8s.networking.ipv6Cidr;
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
      type = types.yk8s.networking.ipv6Cidr;
    };

    bgp_announce_service_ips = mkEnableOption ''
      announcement of the service cluster IP range to external
      BGP peers. By default, only per-node pod networks are announced.
    '';

    bgp_worker_as = mkOption {
      type = types.yk8s.networking.privateUseAutonomousSystemNumber;
      default = 64512;
    };

    bgp_gateway_as = mkOption {
      type = types.yk8s.networking.privateUseAutonomousSystemNumber;
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
  config.yk8s.kubernetes.network.kube_proxy.kubeProxyConfiguration = {
    apiVersion = "kubeproxy.config.k8s.io/v1alpha1";
    kind = "KubeProxyConfiguration";
    metricsBindAddress =
      if config.yk8s.infra.ipv4_enabled
      then "0.0.0.0:10249"
      else "[::]:10249";
    inherit (cfg.kube_proxy) mode;
  };
}
