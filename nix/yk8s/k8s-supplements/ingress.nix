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
  inherit (yk8s-lib.k8s) mkAffinity mkTolerations;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
  inherit
    (yk8s-lib.transform)
    warnIfZero
    ;
in {
  imports = [
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "cpu_request"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "resources" "cpu" "request"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "cpu_limit"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "resources" "cpu" "limit"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "memory_request"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "resources" "memory" "request"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "memory_limit"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "resources" "memory" "limit"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "namespace"] ["k8s-service-layer" "ingress" "helm" "release_namespace"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "helm_repo_url"] ["k8s-service-layer" "ingress" "helm" "chart_repo_url"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "release_name"] ["k8s-service-layer" "ingress" "helm" "release_name"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "chart_version"] ["k8s-service-layer" "ingress" "helm" "chart_version"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "chart_ref"] ["k8s-service-layer" "ingress" "helm" "chart_ref"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "service_type"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "service" "type"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "nodeport_http"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "service" "nodePorts" "http"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "nodeport_https"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "service" "nodePorts" "https"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "enable_ssl_passthrough"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "extraArgs" "enable-ssl-passthrough"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "replica_count"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "replicaCount"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "allow_snippet_annotations"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "allowSnippetAnnotations"])
    (mkRenamedOptionModule ["k8s-service-layer" "ingress" "resources"] ["k8s-service-layer" "ingress" "helm" "values" "controller" "resources"])

    (mkResourceOptionModule ["k8s-service-layer" "ingress"] ["helm" "values" "controller" "resources"] {
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
    scheduling_key = mkOption {
      description = ''
        Scheduling key for the cert manager instance and its resources. Has no
        default.
      '';
      type = with types; nullOr yk8s.k8s.label;
      default = null;
    };
    helm = mkHelmReleaseOptions {
      descriptionName = "ingress-nginx";
      defaultRepoUrl = "https://kubernetes.github.io/ingress-nginx";
      defaultChartRef = "ingress-nginx";
      # renovate: datasource=helm depName=ingress-nginx registryUrl=https://kubernetes.github.io/ingress-nginx
      defaultChartVersion = "4.15.1";
      defaultReleaseNamespace = "k8s-svc-ingress";
      defaultReleaseName = "ingress";
      valuesDocUrl = "https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml";
      chartOptions = {
        controller = {
          service = {
            type = mkOption {
              description = ''
                Service type for the frontend Kubernetes service.
              '';
              type = types.yk8s.k8s.serviceType;
              default = "LoadBalancer";
            };

            nodePorts = {
              http = mkOption {
                description = ''
                  Node port for the HTTP endpoint
                '';
                type = types.port;
                default = 32080;
                apply = v:
                  warnIfZero "config.yk8s.k8s-service-layer.ingress.helm.values.controller.service.nodePorts.http: should not be port zero" v;
              };
              https = mkOption {
                description = ''
                  Node port for the HTTPS endpoint
                '';
                type = types.port;
                default = 32443;
                apply = v:
                  warnIfZero "config.yk8s.k8s-service-layer.ingress.helm.values.controller.service.nodePorts.https: should not be port zero" v;
              };
            };
          };

          replicaCount = mkOption {
            description = ''
              Replica Count
            '';
            type = types.ints.unsigned;
            default = 2;
          };
          allowSnippetAnnotations = mkEnableOption "snippet annotations";

          extraArgs.enable-ssl-passthrough = mkOption {
            description = ''
              Enable SSL passthrough in the controller
            '';
            type = types.bool;
            default = true;
          };
        };
      };
    };
  };
  config.yk8s.k8s-service-layer.ingress.helm.values = let
    inherit (config.yk8s.infra) ipv4_enabled ipv6_enabled;
    affinity = mkAffinity {inherit (cfg) scheduling_key;};
    tolerations = mkTolerations {inherit (cfg) scheduling_key;};
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
        };
        priorityClassName = "system-cluster-critical";
        image.allowPrivilegeEscalation = false;
        admissionWebhooks.patch = {
          inherit tolerations;
        };
      }
      // lib.optionalAttrs config.yk8s.kubernetes.monitoring.enabled {
        metrics = {
          enabled = true;
          serviceMonitor = {
            enabled = true;
            namespace = cfg.helm.release_namespace;
            additionalLabels = config.yk8s.k8s-service-layer.prometheus.common_labels;
          };
        };
      };
  };

  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings = [];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      unflat = [["helm" "values"]];
      ansible_prefix = "k8s_ingress_";
      inventory_path = "all/ingress.yaml";
    })
  ];
}
