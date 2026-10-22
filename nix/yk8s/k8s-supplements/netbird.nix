{
    config,
    lib,
    yk8s-lib,
    ...
}:
let
    cfg = config.yk8s.k8s-service-layer.netbird;
    inherit (lib) mkEnableOption mkOption;
    inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
    # https://cert-manager.io/docs/reference/api-docs/#cert-manager.io%2fv1
    certManagerIssuerKind = types.enum [
      "Issuer"
      "ClusterIssuer"
    ];
in
{
    options.yk8s.k8s-service-layer.netbird = mkTopSection {
      _docs.preface = ''
        Self hosted Netbird server with the dashboard.
        It runs as a single replica on the control plane and stores its state in SQLite on a PVC.
     '';

    enabled = mkEnableOption ''
        Enable the Netbird Server.
        Requires envoy-gateway and cert-manager to be installed and setup.
    '';

    install = mkOption {
        description = ''
            Toggle for installing/uninstalling NetBird.
            IF SET TO FALSE, NETBIRD WILL BE DELETED WITHOUT CHECKING FOR DISRUPTION!
            The data volume and the secrets will only be deleted if disruption is allowed.
        '';
        type = types.bool;
        default = true;
    };
    
    namespace = mkOption {
        description = "Namespace to deploy NetBird into.";
        type = types.yk8s.k8s.namespaceName;
        default = "netbird";
    };

    domain = mkOption {
      description = "Public FQDN of the NetBird Server.";
      type = with types; nullOr yk8s.networking.subdomainName;
      default = null;
      example = "customer.netbird.cloudandheat.com";
    };

    public_port = mkOption {
        description = "Public HTTPS port of the NetBird Management Server and Dashboard.";
        type = types.port;
        default = 443;
    };

    server_image_repository = mkOption {
      type = types.yk8s.k8s.imageRef;
      default = "docker.io/netbirdio/netbird-server";
    };

    dashboard_image_repository = mkOption {
        type = types.yk8s.k8s.imageRef;
        default = "docker.io/netbirdio/dashboard";
    };

    server_image_tag = mkOption {
        type = types.str;
        # renovate: datasource=docker depName=docker.io/netbirdio/netbird-server
        default = "0.81.3";
    };
    dashboard_image_tag = mkOption {
        type = types.str;
        # renovate: datasource=docker depName=docker.io/netbirdio/dashboard
        default = "v2.95.0";
    };



  };

};














