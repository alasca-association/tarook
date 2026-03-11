{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.fluxcd;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
  inherit (yk8s-lib.k8s) mkAffinity mkTolerations;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
in {
  imports = [
    (mkRemovedOptionModule ["k8s-service-layer" "fluxcd" "legacy"] "Support for the legacy FluxCD installation has been dropped.\nYou must switch to an older release and migrate if you have not yet.")
    (mkRenamedOptionModule ["k8s-service-layer" "fluxcd" "helm_repo_url"] ["k8s-service-layer" "fluxcd" "helm" "chart_repo_url"])
    (mkRenamedOptionModule ["k8s-service-layer" "fluxcd" "version"] ["k8s-service-layer" "fluxcd" "helm" "chart_version"])
    (mkRenamedOptionModule ["k8s-service-layer" "fluxcd" "namespace"] ["k8s-service-layer" "fluxcd" "helm" "release_namespace"])
  ];
  options.yk8s.k8s-service-layer.fluxcd = mkTopSection {
    _docs.preface = ''
      More details about our FluxCD2 implementation can be found
      :doc:`here </user/explanation/services/fluxcd>`.

      The following configuration options are available:
    '';

    enabled = mkEnableOption "Flux management";
    install = mkOption {
      description = ''
        If enabled, choose whether to install or uninstall fluxcd2. IF SET TO
        FALSE, FLUXCD2 WILL BE DELETED WITHOUT CHECKING FOR DISRUPTION.
      '';
      type = types.bool;
      default = true;
    };
    helm = mkHelmReleaseOptions {
      descriptionName = "fluxcd";
      defaultRepoUrl = "https://fluxcd-community.github.io/helm-charts";
      defaultChartRef = "flux2";
      # renovate: datasource=helm depName=flux2 registryUrl=https://fluxcd-community.github.io/helm-charts
      defaultChartVersion = "2.16.4";
      defaultReleaseNamespace = "k8s-svc-flux-system";
      defaultReleaseName = "flux2";
      valuesDocUrl = "https://github.com/fluxcd-community/helm-charts/blob/main/charts/flux2/values.yaml";
    };
    scheduling_key = mkOption {
      description = ''
        Scheduling key for the flux instance and its resources. Has no
        default.
      '';
      type = with types; nullOr yk8s.k8s.label;
      default = null;
    };
  };
  config.yk8s.k8s-service-layer.fluxcd.helm.values = let
    affinity = mkAffinity {inherit (cfg) scheduling_key;};
    tolerations = mkTolerations {inherit (cfg) scheduling_key;};
    priorityClassName = "system-cluster-critical";
  in {
    helmController = {
      inherit affinity tolerations priorityClassName;
    };
    imageAutomationController = {
      inherit affinity tolerations priorityClassName;
    };
    imageReflectionController = {
      inherit affinity tolerations priorityClassName;
    };
    kustomizeController = {
      inherit affinity tolerations priorityClassName;
    };
    notificationController = {
      inherit affinity tolerations priorityClassName;
    };
    sourceController = {
      inherit affinity tolerations priorityClassName;
    };
    prometheus = {
      podMonitor = {
        create = config.yk8s.kubernetes.monitoring.enabled;
        # TODO: Hook up to the prometheus-stack configuration
        additionalLabels = {
          "app.kubernetes.io/component" = "monitoring";
          release = "prometheus-stack"; # That's the default podmonitor selector of our prometheus
        };
      };
    };
  };

  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings = [];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "fluxcd_";
      unflat = [
        ["helm" "values"]
      ];
      inventory_path = "all/fluxcd.yaml";
    })
  ];
}
