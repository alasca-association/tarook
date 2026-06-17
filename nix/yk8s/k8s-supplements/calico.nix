{
  options,
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.kubernetes.network.calico;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModule;
  inherit (lib) mkOption;
  inherit (yk8s-lib) mkSubSection types;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
  inherit (yk8s-lib.k8s) mkAffinity;
in {
  imports = [
    (mkRemovedOptionModule ["kubernetes" "network" "calico" "use_tigera_operator"] "")
    (mkRemovedOptionModule ["kubernetes" "network" "calico" "ip_autodetection_method"] "")
    (mkRemovedOptionModule ["kubernetes" "network" "calico" "ipv6_autodetection_method"] "")
    (mkRemovedOptionModule ["kubernetes" "network" "calico" "calico_ip_autodetection_method"] "")
    (mkRemovedOptionModule ["kubernetes" "network" "calico" "calico_ipv6_autodetection_method"] "")
    (mkRemovedOptionModule ["kubernetes" "network" "calico" "values_file_path"] "Please use :ref:`configuration-options.yk8s.kubernetes.network.calico.helm.values` instead.")

    (mkRenamedOptionModule ["kubernetes" "network" "calico" "image_registry"] ["kubernetes" "network" "calico" "helm" "values" "installation" "registry"])
    (mkRenamedOptionModule ["kubernetes" "network" "calico" "mtu"] ["kubernetes" "network" "calico" "helm" "values" "installation" "calicoNetwork" "mtu"])
    (mkRenamedOptionModule ["kubernetes" "network" "calico" "custom_version"] ["kubernetes" "network" "calico" "helm" "chart_version"])
  ];

  options.yk8s.kubernetes.network.calico = mkSubSection {
    _docs.order = 4;
    _docs.preface = ''
      The following configuration options are specific to calico, our CNI
      plugin in use.
    '';
    enabled = mkOption {
      description = ''
        Whether to enable Calico, a high-performance, pure IP networking, policy engine. Calico provides
        layer 3 networking capabilities and associates a virtual router with each node.
        Allows the establishment of zone boundaries through BGP
      '';
      type = types.bool;
      default = true;
    };
    helm = mkHelmReleaseOptions {
      descriptionName = "Calico";
      defaultRepoUrl = "https://docs.tigera.io/calico/charts";
      defaultChartRef = "tigera-operator";
      # renovate: datasource=helm depName=tigera-operator registryUrl=https://docs.tigera.io/calico/charts
      defaultChartVersion = "3.32.1";
      defaultReleaseNamespace = "tigera-operator";
      defaultReleaseName = "calico";
      valuesDocUrl = "https://github.com/projectcalico/calico/blob/master/charts/tigera-operator/values.yaml";
      chartOptions = {
        installation = {
          registry = mkOption {
            description = ''
              Specify the registry endpoint
              Changing this value can be useful if one endpoint hosts outdated images or you're subject to rate limiting
            '';
            type = types.yk8s.networking.subdomainName;
            default = "quay.io";
          };
          controlPlaneReplicas = let
            cp_replicas =
              if config.yk8s.infra.ansible_hosts == null
              then
                builtins.trace
                lib.concatStrings [
                  "INFO: config.yk8s.kubernetes.network.calico.helm.values.installation.controlPlaneReplicas:"
                  " cannot determine number of Kubernetes nodes, so only one replica will be used."
                  " Set the option manually or specify the nodes through config.yk8s.infra.ansible_hosts"
                  " to prevent this behavior, especially if the cluster has 150 nodes or more."
                ]
                1
              else let
                inherit (builtins) length attrNames;
                inherit (config.yk8s.infra.ansible_hosts) masters workers;
                # A single Typha can support hundreds of Felix instances. That means we can
                # safely scale it by the number of k8s nodes divided by fifty and ensure that
                # at least two exist, if we have enough nodes for that
                minimum_number_cp = let
                  nodeCount = length (attrNames (masters.hosts // workers.hosts));
                in
                  lib.max 2 (nodeCount / 50);
                # more typhas than we have k8s masters makes no sense and is also impossible
                # to schedule (once we actually prevent typhas from running on random
                # nodes...), but it could happen on small clusters using the logic above.
                maximum_number_cp = length (attrNames masters.hosts);
                # now we pick the smallest number, because the maximum is a hard maximum and the minimum is a soft minimum
              in
                lib.min minimum_number_cp maximum_number_cp;
          in
            mkOption {
              type = types.ints.positive;
              default = cp_replicas;
              # NOTE: We don't present the calculation of the default value here
              #       because we believe that it's too complex to be helpful
              #       and we'd need to keep it in sync with the actual implementation.
              defaultText = lib.literalExpression "automatic";
            };
          calicoNetwork.mtu = mkOption {
            type = types.ints.positive;
            default =
              if config.yk8s.openstack.enabled
              then config.yk8s.openstack.network_mtu
              else 1500;
            defaultText = lib.literalExpression ''
              if config.yk8s.openstack.enabled
              then config.yk8s.openstack.network_mtu
              else 1500
            '';
          };
        };
      };
    };
    crd.helm = mkHelmReleaseOptions {
      descriptionName = "Calico CRDs";
      defaultRepoUrl = "https://docs.tigera.io/calico/charts";
      defaultChartRef = "crd.projectcalico.org.v1";
      # TODO:
      # At the time of writing, it's unclear whether the CRD chart version must be kept in sync
      # with the operator chart version or not. After some time has passed,
      # it should be decided whether synchronization of both chart versions must be enforced or not.
      # See discussion in: https://gitlab.com/alasca.cloud/tarook/tarook/-/merge_requests/2466#note_3464067306
      # renovate: datasource=helm depName=crd.projectcalico.org.v1 registryUrl=https://docs.tigera.io/calico/charts
      defaultChartVersion = "3.32.1";
      defaultReleaseNamespace = "tigera-operator";
      defaultReleaseName = "calico-crds";
      valuesDocUrl = "https://github.com/projectcalico/calico/blob/master/charts/crd.projectcalico.org.v1/values.yaml";
    };

    encapsulation = mkOption {
      description = ''
        EncapsulationType is the type of encapsulation to use on an IP pool.
        Only takes effect for operator-based installations
        https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.EncapsulationType
      '';
      type = types.enum [
        "IPIP"
        "VXLAN"
        "IPIPCrossSubnet"
        "VXLANCrossSubnet"
        "None"
      ];
      default = "None";
    };
    ipipmode = mkOption {
      description = ''
        Only takes effect for manifest-based installations
        Define if the IP-in-IP encapsulation of calico should be activated
        https://docs.tigera.io/calico/latest/reference/resources/ippool#spec
      '';
      type = types.enum [
        "Always"
        "CrossSubnet"
        "Never"
      ];
      default = "Never";
    };
    bgp_router_id = mkOption {
      description = ''
        An arbitrary ID (four octet unsigned integer) used by Calico as BGP Identifier
      '';
      # as per https://docs.tigera.io/calico/latest/reference/resources/node#bgp#:~:text=routeReflectorClusterID
      type = types.yk8s.networking.ipv4Addr;
      default = "244.0.0.1";
    };
  };

  config.yk8s.kubernetes.network.kube_proxy.enabled = false;
  config.yk8s.kubernetes.network.calico.helm.values =
    {
      installation = {
        enabled = true;
        nodeMetricsPort = 9092;
        typhaMetricsPort = 9093;
        typhaAffinity = mkAffinity {scheduling_key = "node-role.kubernetes.io/control-plane";};
        controlPlaneNodeSelector."node-role.kubernetes.io/control-plane" = "";
        nonPrivileged = "True";
        calicoNetwork = {
          linuxDataplane = "BPF";
          ipPools = let
            common = {
              allowedUses = [
                "Workload"
                "Tunnel"
              ];
              assignmentMode = "Automatic";
              disableBGPExport = false;
              disableNewAllocations = false;
              nodeSelector = "all()";
              encapsulation = cfg.encapsulation;
            };
          in
            (lib.optional config.yk8s.infra.ipv4_enabled
              (common
                // {
                  name = "default-ipv4-ippool";
                  blockSize = 26;
                  cidr = config.yk8s.kubernetes.network.pod_subnet;
                  natOutgoing =
                    if config.yk8s.kubernetes.network.ipv4_nat_outgoing
                    then "Enabled"
                    else "Disabled";
                }))
            ++ (lib.optional config.yk8s.infra.ipv6_enabled
              (common
                // {
                  name = "default-ipv6-ippool";
                  blockSize = 122;
                  cidr = config.yk8s.kubernetes.network.pod_subnet_v6;
                  natOutgoing =
                    if config.yk8s.kubernetes.network.ipv6_nat_outgoing
                    then "Enabled"
                    else "Disabled";
                }));
          nodeAddressAutodetectionV4 = lib.optionalAttrs config.yk8s.infra.ipv4_enabled {
            # This works because calico only uses the routing table and
            # does not actually do a reachability check on layer 3 or so.
            # See also the commit message where this was introduced as to
            # why we don't use the cidrs matcher here.
            canReach = lib.head (lib.match "^(${types.yk8s.networking._regexes.rfc952.ipv4AddrRE})${types.yk8s.networking._regexes.cidr.ipv4SuffixRE}$" config.yk8s.infra.subnet_cidr);
          };
          nodeAddressAutodetectionV6 = lib.optionalAttrs config.yk8s.infra.ipv6_enabled {
            # This works because calico only uses the routing table and
            # does not actually do a reachability check on layer 3 or so.
            # See also the commit message where this was introduced as to
            # why we don't use the cidrs matcher here.
            canReach = lib.head (lib.match "^(${types.yk8s.networking._regexes.rfc3513.ipv6AddressRE})${types.yk8s.networking._regexes.cidr.ipv6SuffixRE}$" config.yk8s.infra.subnet_v6_cidr);
          };
        };
      };
      apiServer.enabled = true;
      nodeSelector = {
        "kubernetes.io/os" = "linux";
        "node-role.kubernetes.io/control-plane" = "";
      };
      kubernetesServiceEndpoint = {
        host = config.yk8s.infra.networking_fixed_ip;
        port = config.yk8s.kubernetes.apiserver.frontend_port;
      };
    }
    // lib.optionalAttrs (lib.versionAtLeast cfg.helm.chart_version "3.30") {
      # https://www.tigera.io/blog/calico-whisker-your-new-ally-in-network-observability/
      # goldmane configures the Calico Goldmane flow aggregator.
      goldmane.enabled = false;
      # whisker configures the Calico Whisker observability UI.
      whisker.enabled = false;
    };

  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings = [];
}
