{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.ingress;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
  inherit (yk8s-lib.types) k8sServiceType k8sSize k8sCpus;
in {
  options.yk8s.k8s-service-layer.ingress = mkTopSection {
    enabled = mkEnableOption "Enable nginx-ingress management.";
    install = mkOption {
      description = ''
        If enabled, choose whether to install or uninstall the ingress. IF SET TO
        FALSE, THE INGRESS CONTROLLER WILL BE DELETED WITHOUT CHECKING FOR
        DISRUPTION.
      '';
      type = types.bool;
      default = true;
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
      default = true; # TODO: value is "true" in ansible role
    };
    replica_count = mkOption {
      description = ''
        Replica Count
      '';
      type = types.ints.positive;
      default = 1;
    };
    allow_snippet_annotations = mkEnableOption "Allow snippet annotations";

    # TODO: deprecate cpu limit (because it shouldnt be set)
    cpu_limit = mkOption {
      description = "CPU resources request for the ingress controller";
      type = types.nullOr k8sCpus;
      default = null;
    };
    cpu_request = mkOption {
      description = "CPU resources request for the ingress controller";
      type = types.nullOr k8sCpus;
      default = "100m";
    };

    # TODO: deprecate memory request (because it should be equal to limit)
    memory_request = mkOption {
      description = ''
        Memory resources request for the ingress controller.
      '';
      type = types.nullOr k8sSize;
      default = cfg.memory_limit;
    };
    memory_limit = mkOption {
      description = ''
        Memory resources limit for the ingress controller.
        For security reasons, a limit is strongly recommended and
        has a direct impact on the security of the cluster,
        for example to prevent a DoS attack.
      '';
      type = types.nullOr k8sSize;
      default = "128Mi";
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
