{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.network;
  inherit (lib) mkOption mkEnableOption types;
  # TODO: type for subnet?
in {
  options.yk8s.kubernetes.network = {
    pod_subnet = mkOption {
      description = ''
        This is the subnet used by Kubernetes for Pods. Subnets will be delegated
        automatically to each node.
      '';
      default = "10.244.0.0/16";
      type = types.str;
    };
    service_subnet = mkOption {
      description = ''
        This is the subnet used by Kubernetes for Services.
      '';
      default = "10.96.0.0/12";
      type = types.str;
    };
    plugin = mkOption {
      description = ''
        Currently only "calico" is supported.

        Calico: High-performance, pure IP networking, policy engine. Calico provides
        layer 3 networking capabilities and associates a virtual router with each node.
        Allows the establishment of zone boundaries through BGP
      '';
      default = "calico";
      type = types.strMatching "calico";
    };
    calico = {
      mtu = mkOption {
        description = "for OpenStack at most 1450";
        type = types.int;
        default = 1450;
      };
      encapsulation = mkOption {
        description = ''
          EncapsulationType is the type of encapsulation to use on an IP pool.
          Only takes effect for operator-based installations
          https://docs.tigera.io/calico/3.25/reference/installation/api#operator.tigera.io/v1.EncapsulationType
        '';
        type = types.strMatching "IPIP|VXLAN|IPIPCrossSubnet|VXLANCrossSubnet|None";
        default = "None";
      };
      ipipmode = mkOption {
        description = ''
          Only takes effect for manifest-based installations
          Define if the IP-in-IP encapsulation of calico should be activated
          https://docs.tigera.io/calico/3.24/reference/resources/ippool#spec
        '';
        type = types.strMatching "Always|CrossSubnet|Never";
        default = "Never";
      };
      calico_ip_autodetection_method = mkOption {
        description = ''
          Make the auto detection method variable as one downside of
          using can-reach mechanism is that it produces additional logs about
          other interfaces i.e. tap interfaces. Also a simpler way will be to
          use an interface to detect ip settings i.e. interface=bond0
        '';
        type = types.str;
        default = "can-reach=www.cloudandheat.com";
      };
      calico_ipv6_autodetection_method = mkOption {
        description = ''
          Make the auto detection method variable as one downside of
          using can-reach mechanism is that it produces additional logs about
          other interfaces i.e. tap interfaces. Also a simpler way will be to
          use an interface to detect ip settings i.e. interface=bond0
        '';
        type = types.str;
        default = "can-reach=www.cloudandheat.com";
      };
      values_file_path = mkOption {
        description = ''
          For the operator-based installation,
          it is possible to link to self-maintained values file for the helm chart
        '';
        type = types.nullOr types.str;
        default = null;
        example = "path-to-a-custom/values.yaml";
      };
      custom_version = mkOption {
        description = ''
          We're mapping a fitting calico version to the configured Kubernetes version.
          You can however pick a custom Calico version.
          Be aware that not all combinations of Kubernetes and Calico versions are recommended:
          https://projectcalico.docs.tigera.io/getting-started/kubernetes/requirements
          Any version should work as long as
          you stick to the calico-Kubernetes compatibility matrix.

          If not specified here, a predefined Calico version will be matched against
          the above specified Kubernetes version.
        '';
        type = types.nullOr types.str;
        default = null;
        example = "3.25.1";
      };
    };
  };
}
