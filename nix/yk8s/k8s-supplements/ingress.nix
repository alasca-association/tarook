{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.ingress;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkResourceOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
  inherit (yk8s-lib.options) mkHelmChartVersionOption;
  inherit
    (yk8s-lib.transform)
    warnIfZero
    ;
in {
  imports = [
    (mkRenamedOptionModule "k8s-service-layer.ingress" "cpu_request" "resources.cpu.request")
    (mkRenamedOptionModule "k8s-service-layer.ingress" "cpu_limit" "resources.cpu.limit")
    (mkRenamedOptionModule "k8s-service-layer.ingress" "memory_request" "resources.memory.request")
    (mkRenamedOptionModule "k8s-service-layer.ingress" "memory_limit" "resources.memory.limit")

    (mkResourceOptionModule "k8s-service-layer.ingress" "resources" {
      description = "Request and limit for the Nginx Ingress controller";
      cpu.request = "100m";
      memory.limit = "128Mi";
    })
  ];

  options.yk8s.k8s-service-layer.ingress = mkTopSection {
    _docs.preface = ''
      The used NGINX ingress controller setup will be explained in more detail
      soon :)

      .. note::

        To enable an ingress controller,
        :ref:`configuration-options.yk8s.k8s-service-layer.ingress.enabled` needs to be set to ``true``.
    '';

    enabled = mkEnableOption "nginx-ingress management.";
    install = mkOption {
      description = ''
        If enabled, choose whether to install or uninstall the ingress. IF SET TO
        FALSE, THE INGRESS CONTROLLER WILL BE DELETED WITHOUT CHECKING FOR
        DISRUPTION.
      '';
      type = types.bool;
      default = true;
    };
    helm_repo_url = mkOption {
      type = types.yk8s.helm.chartRepoUrl;
      default = "https://kubernetes.github.io/ingress-nginx";
    };
    chart_ref = mkOption {
      type = types.yk8s.helm.chartRef;
      default = "ingress-nginx";
    };
    chart_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=ingress-nginx registryUrl=https://kubernetes.github.io/ingress-nginx
      default = "4.13.2";
    };
    release_name = mkOption {
      type = types.yk8s.helm.chartReleaseName;
      default = "ingress";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the ingress in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.yk8s.k8s.namespaceName;
      default = "k8s-svc-ingress";
    };
    service_type = mkOption {
      description = ''
        Service type for the frontend Kubernetes service.
      '';
      type = types.yk8s.k8s.serviceType;
      default = "LoadBalancer";
    };
    scheduling_key = mkOption {
      description = ''
        Scheduling key for the cert manager instance and its resources. Has no
        default.
      '';
      type = with types; nullOr types.yk8s.k8s.label;
      default = null;
    };
    nodeport_http = mkOption {
      description = ''
        Node port for the HTTP endpoint
      '';
      type = types.port;
      default = 32080;
      apply = v:
        warnIfZero "config.yk8s.k8s-service-layer.ingress.nodeport_http: should not be port zero" v;
    };
    nodeport_https = mkOption {
      description = ''
        Node port for the HTTPS endpoint
      '';
      type = types.port;
      default = 32443;
      apply = v:
        warnIfZero "config.yk8s.k8s-service-layer.ingress.nodeport_https: should not be port zero" v;
    };
    enable_ssl_passthrough = mkOption {
      description = ''
        Enable SSL passthrough in the controller
      '';
      type = types.bool;
      default = true;
    };
    replica_count = mkOption {
      description = ''
        Replica Count
      '';
      type = types.ints.unsigned;
      default = 2;
    };
    allow_snippet_annotations = mkEnableOption "snippet annotations";
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "k8s_ingress_";
      inventory_path = "all/ingress.yaml";
    })
  ];
}
