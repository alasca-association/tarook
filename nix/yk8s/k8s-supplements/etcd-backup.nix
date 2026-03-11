{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.etcd-backup;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile types;
  inherit
    (yk8s-lib.transform)
    warnIfZero
    ;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
in {
  imports = [
    (mkRemovedOptionModule ["k8s-service-layer" "etcd-backup" "s3_config_name"] "")
    (mkRemovedOptionModule ["k8s-service-layer" "etcd-backup" "days_of_retention"] "The functionality has been removed. Please manually configure a retention policy, if desired.")

    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "namespace"] ["k8s-service-layer" "etcd-backup" "helm" "release_namespace"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "helm_repo_url"] ["k8s-service-layer" "etcd-backup" "helm" "chart_repo_url"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "name"] ["k8s-service-layer" "etcd-backup" "helm" "release_name"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "chart_version"] ["k8s-service-layer" "etcd-backup" "helm" "chart_version"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "schedule"] ["k8s-service-layer" "etcd-backup" "helm" "values" "schedule"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "metrics_port"] ["k8s-service-layer" "etcd-backup" "helm" "values" "metrics_port"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "bucket_name"] ["k8s-service-layer" "etcd-backup" "helm" "values" "targets" "s3" "bucket"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "addressing_style"] ["k8s-service-layer" "etcd-backup" "helm" "values" "targets" "s3" "addressingStyle"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "secret_name"] ["k8s-service-layer" "etcd-backup" "helm" "values" "targets" "s3" "credentialRef" "name"])
    (mkRenamedOptionModule ["k8s-service-layer" "etcd-backup" "file_prefix"] ["k8s-service-layer" "etcd-backup" "helm" "values" "targets" "s3" "filePrefix"])
  ];

  options.yk8s.k8s-service-layer.etcd-backup = mkTopSection {
    _docs.preface = ''
      Automated etcd backups can be configured in this section. When enabled,
      it periodically creates snapshots of etcd database and stores them in an
      object storage bucket using S3. It uses the helm chart
      `etcdbackup <https://gitlab.com/yaook/operator/-/tree/devel/yaook/helm_builder/Charts/etcd-backup>`__
      present in yaook operator helm chart repository.

      The usage of it is disabled by default, but can be enabled (and
      configured) in the following section. The credentials are stored in
      Vault. By default, they are searched for in the cluster’s kv storage (at
      ``yaook/$clustername/kv``) under ``etcdbackup``. They must be in the
      form of a JSON object/dict with the keys ``access_key`` and
      ``secret_key``.

      The following values need to be set:

      ================== =======================================
      Variable           Description
      ================== =======================================
      ``access_key``     Identifier for your S3 endpoint
      ``secret_key``     Credential for your S3 endpoint
      ``endpoint_url``   URL of your S3 endpoint
      ``certRef``        CA certificate bundle for validation of the endpoint's certificate
      ================== =======================================

      These must be put into a YAML file located at ``config/etcd_backup_s3_config.yaml``.
      The configuration then can be imported to Vault by executing:

      .. note::

        A root token is required.

      .. code:: console

        $ ./managed-k8s/tools/vault/update.sh

      Alternatively, you can also manually insert your configuration into vault.

      .. raw:: html

        <details>
        <summary>etcd-backup configuration template</summary>

      .. literalinclude:: /templates/etcd_backup_s3_config.template.yaml
        :language: yaml

      .. raw:: html

        </details>

      .. important::

        The bucket configured in
        :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.bucket`
        is expected to exist and must be created manually in advance!

      .. raw:: html

        <details>
        <summary>OpenStack: Generate EC2 credentials</summary>

      .. code:: shell

        # Generate access and secret key on OpenStack
        openstack ec2 credentials create

      .. raw:: html

        </details>

      .. raw:: html

        <details>
        <summary>OpenStack: Generate object storage container (bucket)</summary>

      .. code:: shell

        # Generate object storage container on OpenStack
        containername="$(yq --raw-output '.etcd_backup_helm_values.targets.s3.bucket' inventory/yaook-k8s/group_vars/all/etcd-backup.yaml)"
        openstack container create "$containername"

      .. raw:: html

        </details>

      .. raw:: html

        <details>
        <summary>Get certificate chain of S3 endpoint</summary>

      .. code:: shell

        # Get certificate bundle of url
        openssl s_client -connect ENDPOINT_URL:PORT showcerts 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p'

      .. raw:: html

        </details>
    '';

    enabled = mkEnableOption "etcd-backups";
    helm = mkHelmReleaseOptions {
      descriptionName = "etcd-backup";
      defaultRepoUrl = "https://charts.yaook.cloud/operator/stable/";
      defaultChartRef = "etcdbackup";
      # renovate: datasource=helm depName=etcdbackup registryUrl=https://charts.yaook.cloud/operator/stable/
      defaultChartVersion = "1.4.0";
      defaultReleaseNamespace = "kube-system";
      defaultReleaseName = "etcd-backup";
      valuesDocUrl = "https://gitlab.com/yaook/operator/-/blob/devel/yaook/helm_builder/Charts/etcdbackup/values-template.yaml.j2";
      chartOptions = {
        schedule = mkOption {
          description = ''
            Configure value for the cron job schedule for etcd backups.
          '';
          # TODO: Use more specific type
          type = types.nonEmptyStr;
          default = "21 */12 * * *";
        };

        metrics_port = mkOption {
          description = ''
            Metrics port on which the backup-shifter Pod will provide metrics.
            Please note that the etcd-backup deployment runs in host network mode
            for easier access to the etcd cluster.
          '';
          type = types.port;
          default = 19100;
          apply = v:
            warnIfZero "config.yk8s.k8s-service-layer.etcd-backup.metrics_port: should not be port zero" v;
        };
        targets.s3 = {
          endpoint = mkOption {
            description = ''
              Can not be set here and will be supplied dynamically via Ansible.
              See :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup` for how to set the value.
            '';
            readOnly = true;
            default = null;
          };
          bucket = mkOption {
            description = ''
              Name of the s3 bucket to store the backups.

              The bucket is expected to exist and must be created manually in advance!
            '';
            type = types.yk8s.s3.bucketName;
            default = "etcd-backup";
          };
          addressingStyle = mkOption {
            description = ''
              The addressing style used for the s3 bucket that stores the etcd backups.

              - ``path``: Bucket name is included in the URI path.
              - ``virtual``: Bucket name is included in the hostname.
              - ``auto``: Attempts to use virtual, but falls back to path if necessary.
            '';
            # as per https://boto3.amazonaws.com/v1/documentation/api/latest/guide/configuration.html#:~:text=addressing_style:
            type = types.enum [
              "path"
              "virtual"
              "auto"
            ];
            default = "path";
          };
          credentialRef.name = mkOption {
            type = types.yk8s.k8s.secretName;
            default = "etcd-backup-s3-credentials";
          };
          filePrefix = mkOption {
            description = ''
              Prefix for :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.bucket`
            '';
            type = types.yk8s.s3.bucketNamePrefix;
            default = "etcd-backup";
          };
        };
        certRef = mkOption {
          description = ''
            Can not be set here and will be supplied dynamically via Ansible
            See :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup` for how to set the value.
          '';
          readOnly = true;
          default = null;
        };
      };
    };

    vault_mount_point = mkOption {
      description = ''
        Configure the location of the Vault kv2 storage where the credentials can
        be found. This location is the default location used by import.sh and is
        recommended.
      '';
      type = types.yk8s.vault.namespaceName;
      default = "yaook/${config.yk8s.vault.cluster_name}/kv";
      defaultText = lib.literalExpression "\"yaook/\${config.yk8s.vault.cluster_name}/kv\"";
    };
    vault_path = mkOption {
      description = ''
        Configure the kv2 key under which the credentials are found inside Vault.
        This location is the default location used by import.sh and is recommended.

        The role expects a JSON object with `access_key` and `secret_key` keys,
        containing the corresponding S3 credentials.
      '';
      type = types.yk8s.networking.relativeUrlPath;
      default = "etcdbackup";
    };
  };

  config.yk8s.k8s-service-layer.etcd-backup.helm.values = {
    namespace = cfg.helm.release_namespace;

    priorityClassName = "system-cluster-critical";

    serviceMonitor = {
      enabled = config.yk8s.kubernetes.monitoring.enabled;
      additionalLabels = config.yk8s.k8s-service-layer.prometheus.common_labels;
    };
  };

  config.yk8s._targets.ansible.assertions = [];
  config.yk8s._targets.ansible.warnings = [];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      unflat = [
        ["helm" "values"]
      ];
      ansible_prefix = "etcd_backup_";
      inventory_path = "all/etcd-backup.yaml";
      transformations = [
        (
          c:
            yk8s-lib.removeAttrsByPath c [
              ["helm" "values" "certRef"]
              ["helm" "values" "targets" "s3" "endpoint"]
            ]
        )
      ];
    })
  ];
}
