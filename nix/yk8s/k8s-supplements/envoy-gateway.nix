{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.envoy-gateway;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
  inherit (yk8s-lib.k8s) mkAffinity mkTolerations;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
in {
  options.yk8s.k8s-service-layer.envoy-gateway = mkTopSection {
    enabled = mkEnableOption "Envoy Gateway";
    install = mkOption {
      description = ''
        If enabled, choose whether to install or uninstall envoy-gateway. IF SET TO
        FALSE, envoy-gateway WILL BE DELETED WITHOUT CHECKING FOR DISRUPTION.
      '';
      type = types.bool;
      default = true;
    };
    helm = mkHelmReleaseOptions {
      descriptionName = "envoy-gateway";
      defaultChartRef = "oci://docker.io/envoyproxy/gateway-helm";
      # renovate: datasource=docker depName=docker.io/envoyproxy/gateway-helm
      defaultChartVersion = "1.8.3";
      defaultReleaseNamespace = "envoy-gateway-system";
      defaultReleaseName = "envoy-gateway";
      valuesDocUrl = "https://github.com/envoyproxy/gateway/blob/main/charts/gateway-helm/README.md";
    };
    crds.helm = mkHelmReleaseOptions {
      descriptionName = "envoy-gateway-crds";
      defaultChartRef = "oci://docker.io/envoyproxy/gateway-crds-helm";
      # renovate: datasource=docker depName=docker.io/envoyproxy/gateway-crds-helm
      defaultChartVersion = "v1.8.2";
      defaultReleaseNamespace = "envoy-gateway-system";
      defaultReleaseName = "envoy-gateway-crds";
      valuesDocUrl = "https://github.com/envoyproxy/gateway/blob/main/charts/gateway-crds-helm/README.md";
      chartOptions = {
        crds.gatewayAPI.channel = lib.mkOption {
          description = ''
              The `Release Channel <https://gateway-api.sigs.k8s.io/docs/concepts/versioning>`_ to use.

            .. note::

              Switching the channel may involve manual steps. Check the documentation linked above.

          '';
          type = types.enum ["standard" "experimental"];
          default = "standard";
        };
      };
    };
    gateway_class_name = mkOption {
      description = ''
        The name of the default GatewayClass
      '';
      type = types.yk8s.k8s.objectName;
      default = "envoy-gateway";
    };
  };
  config.yk8s.k8s-service-layer.envoy-gateway.helm.values = {
    deployment = {
      priorityClassName = "system-cluster-critical";
      pod = let
        scheduling_key = "node-role.kubernetes.io/control-plane";
      in {
        affinity = mkAffinity {inherit scheduling_key;};
        tolerations = mkTolerations {inherit scheduling_key;};
      };
    };
  };
  config.yk8s.k8s-service-layer.envoy-gateway.crds.helm.values = {
    crds.gatewayAPI.enabled = true;
    crds.envoyGateway.enabled = true;
  };

  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings = [];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "envoy_gateway_";
      unflat = [
        ["helm" "values"]
        ["crds" "helm" "values"]
      ];
      inventory_path = "all/envoy-gateway.yaml";
    })
  ];
}
