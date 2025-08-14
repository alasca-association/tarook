{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.ingress;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkResourceOptionModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
  inherit (yk8s-lib.options) mkHelmChartVersionOption;
  inherit
    (yk8s-lib.types)
    helmChartReleaseName
    helmChartRepoUrl
    helmChartRef
    k8sLabel
    k8sNamespaceName
    k8sServiceType
    ;
  inherit
    (yk8s-lib.transform)
    warnIfZero
    ;
in {
  imports = [
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "cpu_request"] ["k8s-service-layer" "ingress" "resources" "cpu" "request"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "cpu_limit"] ["k8s-service-layer" "ingress" "resources" "cpu" "limit"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "memory_request"] ["k8s-service-layer" "ingress" "resources" "memory" "request"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "memory_limit"] ["k8s-service-layer" "ingress" "resources" "memory" "limit"])

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
      type = helmChartRepoUrl;
      default = "https://kubernetes.github.io/ingress-nginx";
    };
    chart_ref = mkOption {
      type = helmChartRef;
      default = "ingress-nginx";
    };
    chart_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=ingress-nginx registryUrl=https://kubernetes.github.io/ingress-nginx
      default = "4.13.2";
    };
    release_name = mkOption {
      type = helmChartReleaseName;
      default = "ingress";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the ingress in (will be created if it does not exist, but
        never deleted).
      '';
      type = k8sNamespaceName;
      default = "k8s-svc-ingress";
    };
    service_type = mkOption {
      description = ''
        Service type for the frontend Kubernetes service.
      '';
      type = k8sServiceType;
      default = "LoadBalancer";
    };
    scheduling_key = mkOption {
      description = ''
        Scheduling key for the cert manager instance and its resources. Has no
        default.
      '';
      type = with types; nullOr k8sLabel;
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
