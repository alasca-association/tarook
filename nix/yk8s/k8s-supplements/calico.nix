{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.network.calico;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkSubSection;
in {
  imports = [
    (mkRemovedOptionModule "kubernetes" "network.calico.use_tigera_operator" "")
    (mkRemovedOptionModule "kubernetes" "network.calico.ip_autodetection_method" "")
    (mkRemovedOptionModule "kubernetes" "network.calico.ipv6_autodetection_method" "")
    (mkRemovedOptionModule "kubernetes" "network.calico.calico_ip_autodetection_method" "")
    (mkRemovedOptionModule "kubernetes" "network.calico.calico_ipv6_autodetection_method" "")
  ];

  options.yk8s.kubernetes.network.calico = mkSubSection {
    _docs.order = 4;
    _docs.preface = ''
      The following configuration options are specific to calico, our CNI
      plugin in use.
    '';
    mtu = mkOption {
      type = types.int;
      default =
        if config.yk8s.openstack.enabled
        then config.yk8s.openstack.network_mtu
        else 1500;
      defaultText = "\${if config.yk8s.openstack.enabled then config.yk8s.openstack.network_mtu else 1500}";
    };
    encapsulation = mkOption {
      description = ''
        EncapsulationType is the type of encapsulation to use on an IP pool.
        Only takes effect for operator-based installations
        https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.EncapsulationType
      '';
      type = types.strMatching "IPIP|VXLAN|IPIPCrossSubnet|VXLANCrossSubnet|None";
      default = "None";
    };
    ipipmode = mkOption {
      description = ''
        Only takes effect for manifest-based installations
        Define if the IP-in-IP encapsulation of calico should be activated
        https://docs.tigera.io/calico/latest/reference/resources/ippool#spec
      '';
      type = types.strMatching "Always|CrossSubnet|Never";
      default = "Never";
    };
    bgp_router_id = mkOption {
      description = ''
        An arbitrary ID (four octet unsigned integer) used by Calico as BGP Identifier
      '';
      type = types.nonEmptyStr;
      default = "244.0.0.1";
    };
    image_registry = mkOption {
      description = ''
        Specify the registry endpoint
        Changing this value can be useful if one endpoint hosts outdated images or you're subject to rate limiting
      '';
      type = types.nonEmptyStr;
      default = "quay.io";
    };
    values_file_path = mkOption {
      description = ''
        For the operator-based installation,
        it is possible to link to self-maintained values file for the helm chart
      '';
      type = types.nullOr types.nonEmptyStr;
      default = null;
      example = "path-to-a-custom/values.yaml";
    };
    custom_version = mkOption {
      description = ''
        We're mapping a fitting calico version to the configured Kubernetes version.
        You can however pick a custom Calico version.
        Be aware that not all combinations of Kubernetes and Calico versions are recommended:
        https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements
        Any version should work as long as
        you stick to the calico-Kubernetes compatibility matrix.

        If not specified here, a predefined Calico version will be matched against
        the above specified Kubernetes version.
      '';
      type = types.nullOr types.nonEmptyStr;
      default = null;
      example = "3.25.1";
    };
  };
}
