{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.vault;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.k8s-service-layer.vault = mkTopSection {
    enabled = mkEnableOption ''
      Enable HashiCorp Vault management.
      NOTE: On the first run, the unseal keys and the root token will be printed IN
      PLAINTEXT on the ansible output. The unseal keys MUST BE SAVED IN A SECURE
      LOCATION to use the Vault instance in the future!
    '';
    ingress = mkEnableOption ''
      Create a publically reachable ingress resource for the API endpoint of vault.
    '';
    chart_version = mkOption {
      description = ''
        Version of the Helm Chart to use
      '';
      type = types.str;
      default = "0.20.1";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the vault in (will be created if it does not exist, but
        ever deleted).
      '';
      type = types.str;
      default = "k8s-svc-vault";
    };
    dnsnames = mkOption {
      description = ''
        Extra DNS names for which certificates should be prepared.
        NOTE: to work correctly, there must exist an ingress of class `nginx` and it
        must allow ssl passthrough.
      '';
      type = with types; listOf str;
      default = [];
    };
    management_cluster_integration = mkEnableOption ''
      If set to true, the Vault is configured to be exposed via yaook/operator
      infra-ironic, that is, via the integrated DNSmasq to all nodes associated.
      The default is false. This can be enabled in non-infra-ironic clusters,
      without significant damage.
      NOTE: To work in infra-ironic clusters, this requires the vault to be in the
      same namespace as the infra-ironic instance.
      NOTE: if you enable this, you MUST NOT set the service_type to ClusterIP; it
      will default to NodePort and it must be at least NodePort or LoadBalancer for
      the integration to work correctly.
    '';
    init_key_shares = mkOption {
      description = ''
        Number of unseal key shares to generate upon vault initialization.
        NOTE: On the first run, the unseal keys and the root token will be printed IN
        PLAINTEXT on the ansible output. The unseal keys MUST BE SAVED IN A SECURE
        LOCATION to use the Vault instance in the future!
      '';
      type = types.int;
      default = 5;
    };
  };
  config.yk8s.k8s-service-layer.vault = {
    _ansible_prefix = "yaook_vault_";
    _inventory_path = "all/vault-svc.yaml";
  };
}
