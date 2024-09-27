{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.network.calico;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkHelmValuesModule;
  inherit (lib) mkOption types;
  inherit (yk8s-lib) mkSubSection;
  inherit (yk8s-lib.types) ipv4Addr;
in {
  imports = [
    (mkRemovedOptionModule "kubernetes" "network.calico.use_tigera_operator" "")
    (mkRemovedOptionModule "kubernetes" "network.calico.ip_autodetection_method" "")
    (mkRemovedOptionModule "kubernetes" "network.calico.ipv6_autodetection_method" "")
    (mkRemovedOptionModule "kubernetes" "network.calico.calico_ip_autodetection_method" "")
    (mkRemovedOptionModule "kubernetes" "network.calico.calico_ipv6_autodetection_method" "")
    (mkHelmValuesModule "kubernetes" "network.calico.") # trailing dot is not a mistake as this is the prefix
  ];

  options.yk8s.kubernetes.network.calico = mkSubSection {
    _docs.order = 4;
    _docs.preface = ''
      The following configuration options are specific to calico, our CNI
      plugin in use.
    '';
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
      type = ipv4Addr;
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
  config.yk8s.warnings =
    lib.optional (cfg.values_file_path != null)
    "kubernetes.network.calico.values_file_path is deprecated. Use values or extra_values instead";

  config.yk8s.kubernetes.network.calico.default_values = let
    # A single Typha can support hundreds of Felix instances. That means we can
    # safely scale it by the number of k8s nodes divided by fifty and ensure that
    # at least two exist, if we have enough nodes for that
    node_bunches = (builtins.length (builtins.attrNames (config.yk8s.terraform.nodes))) / 50; # TODO this breaks for bare-metal clusters. we need to migrate to yaml hosts files
    target_number = node_bunches;
    minimum_number_cp = lib.max 2 (lib.traceVal node_bunches);
    # more typhas than we have k8s masters makes no sense and is also impossible
    # to schedule (once we actually prevent typhas from running on random
    # nodes...), but it could happen on small clusters using the logic above.
    maximum_number_cp = builtins.length (builtins.filter (n: n.role == "master") (builtins.attrValues config.yk8s.terraform.nodes));
    # now we pick the smallest number, because the maximum is a hard maximum and the minimum is a soft minimum
    cp_replicas = lib.min minimum_number_cp maximum_number_cp;
  in {
    installation = {
      enabled = true;
      nodeMetricsPort = 9092;
      typhaMetricsPort = 9093;
      registry = cfg.image_registry;
      controlPlaneNodeSelector."node-role.kubernetes.io/control-plane" = "";
      nonPrivileged = "True";
      controlPlaneReplicas = cp_replicas;
      calicoNetwork =
        {
          mtu = cfg.mtu;
          ipPools =
            (lib.optional config.yk8s.terraform.ipv4_enabled
              {
                blockSize = 26;
                cidr = config.yk8s.kubernetes.network.pod_subnet;
                natOutgoing =
                  if config.yk8s.kubernetes.network.ipv4_nat_outgoing
                  then "Enabled"
                  else "Disabled";
                nodeSelector = "all()";
                encapsulation = cfg.encapsulation;
              })
            ++ (lib.optional config.yk8s.terraform.ipv6_enabled
              {
                blockSize = 122;
                cidr = config.yk8s.kubernetes.network.pod_subnet_v6;
                natOutgoing =
                  if config.yk8s.kubernetes.network.ipv6_nat_outgoing
                  then "Enabled"
                  else "Disabled";
                nodeSelector = "all()";
                encapsulation = cfg.encapsulation;
              });
        }
        // (lib.optionalAttrs config.yk8s.terraform.ipv4_enabled {
          nodeAddressAutodetectionV4.cidrs = [
            config.yk8s.terraform.subnet_cidr
          ];
        })
        // (lib.optionalAttrs config.yk8s.terraform.ipv6_enabled {
          nodeAddressAutodetectionV6.cidrs = [
            config.yk8s.terraform.subnet_v6_cidr
          ];
        });
    };
    apiServer.enabled = true;
    nodeSelector = {
      "kubernetes.io/os" = "linux";
      "node-role.kubernetes.io/control-plane" = "";
    };
  };
}
