{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.vault;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
  inherit (yk8s-lib.options) mkHelmChartVersionOption;
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
    (mkRenamedOptionModule ["k8s-service-layer" "vault" "active_node_port"] ["k8s-service-layer" "vault" "service_active_node_port"])
  ];
  options.yk8s.k8s-service-layer.vault = mkTopSection {
    enabled = mkEnableOption ''
      HashiCorp Vault management.
      NOTE: On the first run, the unseal keys and the root token will be printed IN
      PLAINTEXT on the ansible output. The unseal keys MUST BE SAVED IN A SECURE
      LOCATION to use the Vault instance in the future!

      For Vault's internal PKI cert-manager needs to be deployed as well
      through :ref:`configuration-options.yk8s.k8s-service-layer.cert-manager`
    '';
    ingress = mkEnableOption ''
      creation of a publically reachable ingress resource for the API endpoint of vault.
    '';

    helm_repo_url = mkOption {
      type = types.yk8s.helm.chartRepoUrl;
      default = "https://helm.releases.hashicorp.com";
    };

    ca_issuer_kind = mkOption {
      type = certManagerIssuerKind;
      default = "Issuer";
    };

    ca_issuer = mkOption {
      # type as per https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec
      type = types.yk8s.k8s.objectName;
      default = "selfsigned-issuer";
    };

    backup_approle_path = mkOption {
      type = types.yk8s.vault.namespaceName;
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
      type = types.yk8s.k8s.namespaceName;
      default = "k8s-svc-vault";
    };
    dnsnames = mkOption {
      description = ''
        Extra DNS names for which certificates should be prepared.
        NOTE: to work correctly, there must exist an ingress of class `nginx` and it
        must allow ssl passthrough.
      '';
      type = with types; listOf yk8s.networking.subdomainName;
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
      type = with types; nullOr yk8s.k8s.label;
      default = null;
    };
    storage_class = mkOption {
      description = ''
        Storage class for the vault file storage backend.
      '';
      type = types.yk8s.k8s.storageClassName;
      default = "csi-sc-cinderplugin";
    };
    storage_size = mkOption {
      description = ''
        Storage size for the vault file storage backend.
      '';
      type = types.yk8s.k8s.quantity;
      default = "8Gi";
    };

    external_ingress_class = mkOption {
      type = types.yk8s.k8s.ingressClassName;
      default = "nginx";
    };

    external_ingress_issuer_name = mkOption {
      description = ''
        If :ref:`configuration-options.yk8s.k8s-service-layer.vault.ingress` is set to ``true`` and :ref:`configuration-options.yk8s.k8s-service-layer.vault.dnsnames` is not empty, you have to tell the LCM which (Cluster)Issuer to use
        for your ACME service.
      '';
      # type as per https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec
      type = with types; nullOr yk8s.k8s.issuerName;
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
      type = with types; nullOr yk8s.posix.relativePath;
      default = null;
      example = "vault/backup_s3_config.yaml";
    };
    backup_s3_addressing_style = mkOption {
      description = ''
        The addressing style used for the s3 bucket that stores the vault backups.

        - ``path``: Bucket name is included in the URI path.
        - ``virtual``: Bucket name is included in the hostname.
        - ``auto``: Attempts to use virtual, but falls back to path if necessary.

        Only relevant if :ref:`configuration-options.yk8s.k8s-service-layer.vault.enable_backups` is set to ``true``.
      '';
      # as per https://boto3.amazonaws.com/v1/documentation/api/latest/guide/configuration.html#:~:text=addressing_style:
      type = types.enum [
        "path"
        "virtual"
        "auto"
      ];
      default = "path";
    };
    backup_s3_bucket = mkOption {
      description = ''
        Configure the S3 bucket name to which vault backups will be written.

        Only relevant if :ref:`configuration-options.yk8s.k8s-service-layer.vault.enable_backups` is set to ``true``.
      '';
      type = types.yk8s.s3.bucketName;
      default = "vault-backup";
    };
    service_type = mkOption {
      description = ''
        Type of the Kubernetes Service of the Vault
        NOTE: You may set this to LoadBalancer, but note that this will still use the internal certificate.
        If you want to expose the Vault to the outside world, use the ingress config above.
      '';
      type = types.yk8s.k8s.serviceType;
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
  config.yk8s._targets.ansible.assertions = [
    {
      assertion = cfg.enabled -> config.yk8s.k8s-service-layer.cert-manager.enabled;
      message = lib.strings.concatStrings [
        "config.yk8s.k8s-service-layer.vault.enabled:"
        " requires `config.yk8s.k8s-service-layer.cert-manager.enabled=true`"
        " when true"
        " because Vault's internal PKI is created with cert-manager."
      ];
    }
  ];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "yaook_vault_";
      inventory_path = "all/vault-svc.yaml";
    })
  ];
}
