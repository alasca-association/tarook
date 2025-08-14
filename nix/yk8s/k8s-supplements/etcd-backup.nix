{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.etcd-backup;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedOptionModule mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile;
  inherit
    (yk8s-lib.types)
    k8sSecretName
    posixPathSegment
    relativeUrlPath
    s3BucketName
    s3BucketNamePrefix
    vaultNamespaceName
    ;
  inherit
    (yk8s-lib.transform)
    warnIfZero
    ;
  inherit (yk8s-lib.options) mkHelmReleaseOptions;
in {
  imports = [

    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "namespace" "helm.release_namespace")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "helm_repo_url" "helm.chart_repo_url")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "name" "helm.release_name")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "chart_version" "helm.chart_version")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "schedule" "helm.values.schedule")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "metrics_port" "helm.values.metrics_port")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "bucket_name" "helm.values.targets.s3.bucket")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "addressing_style" "helm.values.targets.s3.addressingStyle")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "secret_name" "helm.values.targets.s3.credentialRef.name")
    (mkRenamedOptionModule "k8s-service-layer.etcd-backup" "file_prefix" "helm.values.targets.s3.filePrefix")
    (mkRemovedOptionModule ["k8s-service-layer" "etcd-backup" "s3_config_name"] "")
  ];

  options.yk8s.k8s-service-layer.etcd-backup = mkTopSection {
    _docs.preface = ''
      Automated etcd backups can be configured in this section. When enabled
      it periodically creates snapshots of etcd database and store it in a
      object storage using s3. It uses the helm chart
      `etcdbackup <https://gitlab.com/yaook/operator/-/tree/devel/yaook/helm_builder/Charts/etcd-backup>`__
      present in yaook operator helm chart repository. The object storage
      retains data for 30 days then deletes it.

      The usage of it is disabled by default but can be enabled (and
      configured) in the following section. The credentials are stored in
      Vault. By default, they are searched for in the cluster’s kv storage (at
      ``yaook/$clustername/kv``) under ``etcdbackup``. They must be in the
      form of a JSON object/dict with the keys ``access_key`` and
      ``secret_key``.

      .. note::

        To enable etcd-backup,
        :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.enabled`
        needs to be set to ``true``.

      The following values need to be set:

      ================== =======================================
      Variable           Description
      ================== =======================================
      ``access_key``     Identifier for your S3 endpoint
      ``secret_key``     Credential for your S3 endpoint
      ``endpoint_url``   URL of your S3 endpoint
      ``certRef``        Certificate bundle of the endpoint.
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

      .. raw:: html

        <details>
        <summary>Generate/Figure out etcd-backup configuration values</summary>

      .. code:: shell

        # Generate access and secret key on OpenStack
        openstack ec2 credentials create

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
      defaultChartVersion = "0.20250724.0";
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
            '';
            type = s3BucketName;
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
            type = k8sSecretName;
            default = "etcd-backup-s3-credentials";
          };
          filePrefix = mkOption {
            description = ''
              Prefix for :ref:`configuration-options.yk8s.k8s-service-layer.etcd-backup.helm.values.targets.s3.bucket`
            '';
            type = s3BucketNamePrefix;
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
      type = vaultNamespaceName;
      default = "yaook/${config.yk8s.vault.cluster_name}/kv";
      defaultText = "yaook/\${config.yk8s.vault.cluster_name}/kv";
    };
    vault_path = mkOption {
      description = ''
        Configure the kv2 key under which the credentials are found inside Vault.
        This location is the default location used by import.sh and is recommended.

        The role expects a JSON object with `access_key` and `secret_key` keys,
        containing the corresponding S3 credentials.
      '';
      type = relativeUrlPath;
      default = "etcdbackup";
    };
    days_of_retention = mkOption {
      description = ''
        Number of days after which individual items in the bucket are dropped. Enforced by S3 lifecyle rules which
        are also implemented by Ceph's RGW.
      '';
      type = types.ints.unsigned;
      default = 30;
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

  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      unflat = ["helm.values"];
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
