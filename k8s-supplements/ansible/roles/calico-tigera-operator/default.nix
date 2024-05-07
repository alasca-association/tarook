{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.network.calico;
  removed-lib = import ../../../../nix/module/lib/removed.nix {inherit lib;};
  inherit (removed-lib) mkRemovedOptionModule;
  inherit (lib) mkOption types;
in {
  imports = [
    (mkRemovedOptionModule "kubernetes" "network.calico.use_tigera_operator" "")
  ];

  options.yk8s.kubernetes.network.calico = {
    mtu = mkOption {
      description = "for OpenStack at most 1450";
      type = types.int;
      default = config.yk8s.terraform.network_mtu;
      defaultText = "\${config.yk8s.terraform.network_mtu}";
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
      # TODO: is this never used?
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
      # TODO: is this never used?
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
}
