{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.cert-manager;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
  inherit (yk8s-lib.k8s) mkAffinity mkTolerations;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
in {
  imports = [
    (mkRenamedOptionModule ["k8s-service-layer" "cert-manager" "namespace"] ["k8s-service-layer" "cert-manager" "helm" "release_namespace"])
    (mkRenamedOptionModule ["k8s-service-layer" "cert-manager" "helm_repo_url"] ["k8s-service-layer" "cert-manager" "helm" "chart_repo_url"])
    (mkRenamedOptionModule ["k8s-service-layer" "cert-manager" "release_name"] ["k8s-service-layer" "cert-manager" "helm" "release_name"])
    (mkRenamedOptionModule ["k8s-service-layer" "cert-manager" "chart_version"] ["k8s-service-layer" "cert-manager" "helm" "chart_version"])
    (mkRenamedOptionModule ["k8s-service-layer" "cert-manager" "chart_ref"] ["k8s-service-layer" "cert-manager" "helm" "chart_ref"])
  ];
  options.yk8s.k8s-service-layer.cert-manager = mkTopSection {
    _docs.preface = ''
      The used Cert-Manager controller setup will be explained in more detail
      soon :)

        .. note::

            To enable cert-manager,
            :ref:`configuration-options.yk8s.k8s-service-layer.cert-manager.enabled`
            needs to be set to ``true``.
    '';

    enabled = mkEnableOption "management of a cert-manager.io instance";
    install = mkOption {
      description = ''
        Install or uninstall cert manager. If set to false, the cert-manager will be
        uninstalled WITHOUT CHECK FOR DISRUPTION!
      '';
      type = types.bool;
      default = true;
    };
    helm = mkHelmReleaseOptions {
      descriptionName = "cert-manager";
      defaultRepoUrl = "https://charts.jetstack.io";
      defaultChartRef = "cert-manager";
      # renovate: datasource=helm depName=cert-manager registryUrl=https://charts.jetstack.io
      defaultChartVersion = "1.19.2";
      defaultReleaseNamespace = "k8s-svc-cert-manager";
      defaultReleaseName = "cert-manager";
      valuesDocUrl = "https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml";
      chartOptions = {
      };
    };

    scheduling_key = mkOption {
      description = ''
        Scheduling key for the cert manager instance and its resources. Has no
        default.
      '';
      type = with types; nullOr yk8s.k8s.label;
      default = null;
    };
    letsencrypt_email = mkOption {
      description = ''
        If given, a *cluster wide* Let's Encrypt issuer with that email address will
        be generated. Requires an ingress to work correctly.
        DO NOT ENABLE THIS IN CUSTOMER CLUSTERS, BECAUSE THEY SHOULD NOT CREATE
        CERTIFICATES UNDER OUR NAME. Customers are supposed to deploy their own
        ACME/Let's Encrypt issuer.
      '';
      type = with types; nullOr yk8s.networking.emailAddress;
      default = null;
    };
    letsencrypt_preferred_chain = mkOption {
      description = ''
        By default, the ACME issuer will let the server choose the certificate chain
        to use for the certificate. This can be used to override it.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
    };
    letsencrypt_ingress = mkOption {
      description = ''
        The ingress class to use for responding to the ACME challenge.
        The default value works for the default k8s-service-layer.ingress
        configuration and may need to be adapted in case a different ingress is to be
        used.
      '';
      type = types.nonEmptyStr;
      default = "nginx"; # TODO: get value from config.yk8s.k8s-service-layer.ingress once we have extraValues
    };
    letsencrypt_server = mkOption {
      description = ''
        This variable let's you specify the endpoint of the ACME issuer. A common usecase
        is to switch between staging and production.
        See https://letsencrypt.org/docs/staging-environment/
      '';
      type = types.yk8s.networking.httpxHostPathUrl;
      default = "https://acme-v02.api.letsencrypt.org/directory";
      example = "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
  };
  config.yk8s.k8s-service-layer.cert-manager.helm.values = let
    affinity = mkAffinity {inherit (cfg) scheduling_key;};
    tolerations = mkTolerations {inherit (cfg) scheduling_key;};
  in
    {
      installCRDs = true;
      global.priorityClassName = "system-cluster-critical";
      inherit affinity tolerations;
      cainjector = {inherit affinity tolerations;};
      webhook = {inherit affinity tolerations;};
    }
    // lib.optionalAttrs config.yk8s.kubernetes.monitoring.enabled {
      prometheus = {
        enabled = true;
        servicemonitor.enabled = true;
        servicemonitor.labels = config.yk8s.k8s-service-layer.prometheus.common_labels;
      };
    };
  config.yk8s._inventory_packages = [
    (
      mkGroupVarsFile {
        inherit cfg;
        only_if_enabled = true;
        unflat = [
          ["helm" "values"]
        ];
        ansible_prefix = "k8s_cert_manager_";
        inventory_path = "all/cert-manager.yaml";
      }
    )
  ];
}
