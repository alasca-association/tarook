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
  inherit (yk8s-lib.types) k8sServiceType k8sSize k8sCpus;
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
      .. _cluster-configuration.nginx-ingress-configuration:

      NGINX Ingress Controller Configuration
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      The used NGINX ingress controller setup will be explained in more detail
      soon :)

      .. note::

        To enable an ingress controller,
        ``k8s-service-layer.ingress.enabled`` needs to be set to ``true``.
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
      type = types.str;
      default = "https://kubernetes.github.io/ingress-nginx";
    };
    chart_ref = mkOption {
      type = types.str;
      default = "ingress-nginx/ingress-nginx";
    };
    chart_version = mkOption {
      type = types.str;
      default = "4.11.1";
    };
    release_name = mkOption {
      type = types.str;
      default = "ingress";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the ingress in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.str;
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
      type = with types; nullOr str;
      default = null;
    };
    nodeport_http = mkOption {
      description = ''
        Node port for the HTTP endpoint
      '';
      type = types.port;
      default = 32080;
    };
    nodeport_https = mkOption {
      description = ''
        Node port for the HTTPS endpoint
      '';
      type = types.port;
      default = 32443;
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
      type = types.ints.positive;
      default = 1;
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
