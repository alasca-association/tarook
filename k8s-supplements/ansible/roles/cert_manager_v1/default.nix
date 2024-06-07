{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.cert-manager;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.k8s-service-layer.cert-manager = mkTopSection {
    enabled = mkEnableOption "Enable management of a cert-manager.io instance";
    namespace = mkOption {
      description = ''
        Configure in which namespace the cert-manager is run. The namespace is
        created automatically, but never deleted automatically.
      '';
      type = types.str;
      default = "k8s-svc-cert-manager";
    };
    install = mkOption {
      description = ''
        Install or uninstall cert manager. If set to false, the cert-manager will be
        uninstalled WITHOUT CHECK FOR DISRUPTION!
      '';
      type = types.bool;
      default = true;
    };
    scheduling_key = mkOption {
      description = ''
        Scheduling key for the cert manager instance and its resources. Has no
        default.
      '';
      type = types.str;
      default = ""; # TODO or null?
    };
    letsencrypt_email = mkOption {
      description = ''
        If given, a *cluster wide* Let's Encrypt issuer with that email address will
        be generated. Requires an ingress to work correctly.
        DO NOT ENABLE THIS IN CUSTOMER CLUSTERS, BECAUSE THEY SHOULD NOT CREATE
        CERTIFICATES UNDER OUR NAME. Customers are supposed to deploy their own
        ACME/Let's Encrypt issuer.
      '';
      type = with types; nullOr str;
      default = null; # TODO or ""?
    };
    letsencrypt_preferred_chain = mkOption {
      description = ''
        By default, the ACME issuer will let the server choose the certificate chain
        to use for the certificate. This can be used to override it.
      '';
      type = with types; nullOr str;
      default = null; # TODO or ""?
    };
    letsencrypt_ingress = mkOption {
      description = ''
        The ingress class to use for responding to the ACME challenge.
        The default value works for the default k8s-service-layer.ingress
        configuration and may need to be adapted in case a different ingress is to be
        used.
      '';
      type = types.str;
      default = "nginx"; # TODO: get value from config.yk8s.k8s-service-layer.ingress...
    };
    letsencrypt_server = mkOption {
      description = ''
        This variable let's you specify the endpoint of the ACME issuer. A common usecase
        is to switch between staging and production.
        See https://letsencrypt.org/docs/staging-environment/
      '';
      type = with types; nullOr str;
      default = null;
      example = "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
  };
  config.yk8s.k8s-service-layer.cert-manager = {
    _only_if_enabled = true;
    _ansible_prefix = "k8s_cert_manager_";
    _inventory_path = "all/cert-manager.yaml";
  };
}
