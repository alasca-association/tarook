{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.vault;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
  inherit (yk8s-lib.types) k8sSize k8sServiceType;
in {
  options.yk8s.k8s-service-layer.vault = mkTopSection {
    enabled = mkEnableOption ''
      HashiCorp Vault management.
      NOTE: On the first run, the unseal keys and the root token will be printed IN
      PLAINTEXT on the ansible output. The unseal keys MUST BE SAVED IN A SECURE
      LOCATION to use the Vault instance in the future!
    '';
    ingress = mkEnableOption ''
      creation of a publically reachable ingress resource for the API endpoint of vault.
    '';

    helm_repo_url = mkOption {
      type = types.nonEmptyStr;
      default = "https://helm.releases.hashicorp.com";
    };

    ca_issuer_kind = mkOption {
      type = types.nonEmptyStr;
      default = "Issuer";
    };

    ca_issuer = mkOption {
      type = types.nonEmptyStr;
      default = "selfsigned-issuer";
    };

    backup_approle_path = mkOption {
      type = types.nonEmptyStr;
      default = "yaook/vault_v1/approle/";
    };

    chart_version = mkOption {
      description = ''
        Version of the Helm Chart to use
      '';
      type = types.str;
      default = "0.23.0";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the vault in (will be created if it does not exist, but
        ever deleted).
      '';
      type = types.nonEmptyStr;
      default = "k8s-svc-vault";
    };
    dnsnames = mkOption {
      description = ''
        Extra DNS names for which certificates should be prepared.
        NOTE: to work correctly, there must exist an ingress of class `nginx` and it
        must allow ssl passthrough.
      '';
      type = with types; listOf nonEmptyStr;
      default = [];
    };
    management_cluster_integration = mkEnableOption ''
      management cluster integration.
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
    init_key_threshold = mkOption {
      description = ''
        Threshold for the Shamir's Secret Sharing Scheme used for unsealing, i.e. the
        number of shares required to unseal the vault after a restart
        NOTE: On the first run, the unseal keys and the root token will be printed IN
        PLAINTEXT on the ansible output. The unseal keys MUST BE SAVED IN A SECURE
        LOCATION to use the Vault instance in the future!
      '';
      type = types.int;
      default = 2;
    };
    scheduling_key = mkOption {
      description = ''
        Scheduling key for the vault instance and its resources. Has no default.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
    };
    storage_class = mkOption {
      description = ''
        Storage class for the vault file storage backend.
      '';
      type = types.nonEmptyStr;
      default = "csi-sc-cinderplugin";
    };
    storage_size = mkOption {
      description = ''
        Storage size for the vault file storage backend.
      '';
      type = k8sSize;
      default = "8Gi";
    };

    external_ingress_class = mkOption {
      type = types.nonEmptyStr;
      default = "nginx";
    };

    external_ingress_issuer_name = mkOption {
      description = ''
        If `ingress=True` and `dnsnames` is not empty, you have to tell the LCM which (Cluster)Issuer to use
        for your ACME service.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
      apply = v:
        if
          cfg.ingress
          && cfg.dnsnames != []
          && v == null
        then
          throw
          "[k8s-service-layer.vault] If `ingress=true` and `dnsnames` is not empty, you have to set external_ingress_issuer_name"
        else v;
    };
    external_ingress_issuer_kind = mkOption {
      description = ''
        Can be `Issuer` or `ClusterIssuer`, depending on the kind of issuer you would like
        to use for externally facing certificates.
      '';
      type = types.strMatching "(Cluster)?Issuer";
      default = "ClusterIssuer";
    };
    enable_backups = mkOption {
      description = ''
        If `true`, then an additional backup service will be deployed which creates snapshots and stores
        them in an S3 bucket.
      '';
      type = types.bool;
      default = true;
    };
    s3_config_file = mkOption {
      description = ''
        Credentials to access an S3 bucket to which the backups will be written. Required if `enable_backups = true`.
        You can find a template in `managed-k8s/templates/vault_backup_s3_config.template.yaml`.
      '';
      type = types.nonEmptyStr;
      default = "vault_backup_s3_config.yaml";
    };
    service_type = mkOption {
      description = ''
        Type of the Kubernetes Service of the Vault
        NOTE: You may set this to LoadBalancer, but note that this will still use the internal certificate.
        If you want to expose the Vault to the outside world, use the ingress config above.
      '';
      type = k8sServiceType;
      # TODO confliction values: role had
      # "{{ yaook_vault_management_cluster_integration | ternary('NodePort', 'ClusterIP') }}"
      # which is a setting that doesn't exist

      default = "ClusterIP";
    };
    active_node_port = mkOption {
      description = ''
        Node port to use for the Service which exposes the active Vault instance
        See NOTE above regarding exposure of the Vault.
      '';
      type = types.port;
      default = 32048;
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "yaook_vault_";
      inventory_path = "all/vault-svc.yaml";
    })
  ];
}
