{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.vault;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkHelmChartVersionOption;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
  inherit
    (yk8s-lib.types)
    helmChartRepoUrl
    k8sIngressClassName
    k8sIssuerName
    k8sLabel
    k8sNamespaceName
    k8sQuantity
    k8sServiceType
    k8sStorageClassName
    k8sObjectName
    relativePosixPath
    subdomainName
    vaultNamespaceName
    ;
  inherit
    (yk8s-lib.transform)
    warnIfZero
    ;
  # as per https://cert-manager.io/docs/reference/api-docs/#cert-manager.io%2fv1
  certManagerIssuerKind = types.enum [
    "Issuer"
    "ClusterIssuer"
  ];
in {
  imports = [
    (mkRenamedOptionModule "k8s-service-layer.vault" "active_node_port" "service_active_node_port")
  ];
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
      type = helmChartRepoUrl;
      default = "https://helm.releases.hashicorp.com";
    };

    ca_issuer_kind = mkOption {
      type = certManagerIssuerKind;
      default = "Issuer";
    };

    ca_issuer = mkOption {
      # type as per https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec
      type = k8sObjectName;
      default = "selfsigned-issuer";
    };

    backup_approle_path = mkOption {
      type = vaultNamespaceName;
      default = "yaook/vault_v1/approle";
    };

    chart_version = mkHelmChartVersionOption {
      # renovate: datasource=helm depName=vault registryUrl=https://helm.releases.hashicorp.com
      default = "0.23.0";
    };
    namespace = mkOption {
      description = ''
        Namespace to deploy the vault in (will be created if it does not exist, but
        ever deleted).
      '';
      type = k8sNamespaceName;
      default = "k8s-svc-vault";
    };
    dnsnames = mkOption {
      description = ''
        Extra DNS names for which certificates should be prepared.
        NOTE: to work correctly, there must exist an ingress of class `nginx` and it
        must allow ssl passthrough.
      '';
      type = with types; listOf subdomainName;
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
      type = with types; nullOr k8sLabel;
      default = null;
    };
    storage_class = mkOption {
      description = ''
        Storage class for the vault file storage backend.
      '';
      type = k8sStorageClassName;
      default = "csi-sc-cinderplugin";
    };
    storage_size = mkOption {
      description = ''
        Storage size for the vault file storage backend.
      '';
      type = k8sQuantity;
      default = "8Gi";
    };

    external_ingress_class = mkOption {
      type = k8sIngressClassName;
      default = "nginx";
    };

    external_ingress_issuer_name = mkOption {
      description = ''
        If :ref:`configuration-options.yk8s.k8s-service-layer.vault.ingress` is set to ``true`` and :ref:`configuration-options.yk8s.k8s-service-layer.vault.dnsnames` is not empty, you have to tell the LCM which (Cluster)Issuer to use
        for your ACME service.
      '';
      # type as per https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec
      type = with types; nullOr k8sIssuerName;
      default = null;
      apply = v:
        if
          cfg.ingress
          && cfg.dnsnames != []
          && v == null
        then
          throw
          "config.yk8s.k8s-service-layer.vault.external_ingress_issuer_name: must be set because config.yk8s.k8s-service-layer.vault.ingress=true and config.yk8s.k8s-service-layer.vault.dnsnames!=[]"
        else v;
    };
    external_ingress_issuer_kind = mkOption {
      description = ''
        Can be `Issuer` or `ClusterIssuer`, depending on the kind of issuer you would like
        to use for externally facing certificates.
      '';
      type = certManagerIssuerKind;
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
        Credentials to access an S3 bucket to which the backups will be written. Required if :ref:`configuration-options.yk8s.k8s-service-layer.vault.enable_backups` is set to ``true``
        You can find a template in `managed-k8s/templates/vault_backup_s3_config.template.yaml`.

        Note: The given path is interpreted as being relative to the cluster repo's config directory.
      '';
      # NOTE: Not using `pathInStore` here because the expected file contains secrets
      # TODO: Eliminate config option and store secrets solely in Vault
      type = with types; nullOr relativePosixPath;
      default = null;
      example = "./vault/backup_s3_config.yaml";
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
    service_active_node_port = mkOption {
      description = ''
        Node port to use for the Service which exposes the active Vault instance
        See NOTE above regarding exposure of the Vault.
      '';
      type = types.port;
      default = 32048;
      apply = v:
        warnIfZero "config.yk8s.k8s-service-layer.vault.service_active_node_port: should not be port zero" v;
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
