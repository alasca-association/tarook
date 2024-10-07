{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.ingress;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkResourceOptionModule mkHelmValuesModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkAffinity mkTolerations;
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

    (mkHelmValuesModule "k8s-service-layer.ingress" "")
  ];

  options.yk8s.k8s-service-layer.ingress = mkTopSection {
    _docs.preface = ''
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
      type = types.nonEmptyStr;
      default = "https://kubernetes.github.io/ingress-nginx";
    };
    chart_ref = mkOption {
      type = types.nonEmptyStr;
      default = "ingress-nginx/ingress-nginx";
    };
    chart_version = mkOption {
      type = types.str;
      default = "4.11.1";
    };
    release_name = mkOption {
      type = types.nonEmptyStr;
      default = "ingress";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the ingress in (will be created if it does not exist, but
        never deleted).
      '';
      type = types.nonEmptyStr;
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
      type = with types; nullOr nonEmptyStr;
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
  config.yk8s.k8s-service-layer.ingress.default_values = let
    inherit (config.yk8s.terraform) ipv4_enabled ipv6_enabled;
    affinity = mkAffinity {inherit (cfg) scheduling_key;};
    tolerations = mkTolerations cfg.scheduling_key;
  in {
    defaultBackend = {inherit affinity tolerations;};
    controller =
      {
        inherit affinity tolerations;
        service = {
          ipFamilyPolicy =
            if ipv4_enabled && ipv6_enabled
            then "PreferDualStack"
            else "SingleStack";
          ipFamilies =
            (lib.optional ipv4_enabled "IPv4")
            ++ (lib.optional ipv6_enabled "IPv6");
          type = cfg.service_type;
          nodePorts = {
            http = cfg.nodeport_http;
            https = cfg.nodeport_https;
          };
        };
        extraArgs.enable-ssl-passthrough = cfg.enable_ssl_passthrough;
        priorityClassName = "system-cluster-critical";
        replicaCount = cfg.replica_count;
        allowSnippetAnnotations = cfg.allow_snippet_annotations;
        image.allowPrivilegeEscalation = false;
        resources = cfg.resources;
      }
      // lib.optionalAttrs config.yk8s.kubernetes.monitoring.enabled {
        metrics = {
          enabled = true;
          serviceMonitor = {
            enabled = true;
            namespace = cfg.namespace;
            additionalLabels = config.yk8s.k8s-service-layer.prometheus.common_labels;
          };
        };
      };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "k8s_ingress_";
      inventory_path = "all/ingress.yaml";
    })
  ];
}
