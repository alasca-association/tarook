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
in {
  imports = [
    (mkRemovedOptionModule "k8s-service-layer.etcd-backup" "s3_config_name" "")
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
        ``k8s-service-layer.etcd-backup.enabled`` needs to be set to
        ``true``.

      The following values need to be set:

      ================== =======================================
      Variable           Description
      ================== =======================================
      ``access_key``     Identifier for your S3 endpoint
      ``secret_key``     Credential for your S3 endpoint
      ``endpoint_url``   URL of your S3 endpoint
      ``endpoint_cacrt`` Certificate bundle of the endpoint.
      ================== =======================================

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
    secret_name = mkOption {
      type = types.nonEmptyStr;
      default = "etcd-backup-s3-credentials";
    };
    namespace = mkOption {
      type = types.nonEmptyStr;
      default = "kube-system";
    };
    helm_repo_url = mkOption {
      type = types.nonEmptyStr;
      default = "https://charts.yaook.cloud/operator/stable/";
    };
    name = mkOption {
      type = types.nonEmptyStr;
      default = "etcd-backup";
    };
    schedule = mkOption {
      description = ''
        Configure value for the cron job schedule for etcd backups.
      '';
      type = types.nonEmptyStr;
      default = "21 */12 * * *";
    };
    bucket_name = mkOption {
      description = ''
        Name of the s3 bucket to store the backups.
      '';
      type = types.nonEmptyStr;
      default = "etcd-backup";
    };
    file_prefix = mkOption {
      description = ''
        Name of the folder to keep the backup files.
      '';
      type = types.str;
      default = "etcd-backup";
    };
    vault_mount_point = mkOption {
      description = ''
        Configure the location of the Vault kv2 storage where the credentials can
        be found. This location is the default location used by import.sh and is
        recommended.
      '';
      type = types.nonEmptyStr;
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
      type = types.nonEmptyStr;
      default = "etcdbackup";
    };
    days_of_retention = mkOption {
      description = ''
        Number of days after which individual items in the bucket are dropped. Enforced by S3 lifecyle rules which
        are also implemented by Ceph's RGW.
      '';
      type = types.int;
      default = 30;
    };
    chart_version = mkOption {
      description = ''
        etcdbackup chart version to install.
        If this is not specified, the latest version is installed.
      '';
      type = types.str;
      default = "";
    };
    metrics_port = mkOption {
      description = ''
        Metrics port on which the backup-shifter Pod will provide metrics.
        Please note that the etcd-backup deployment runs in host network mode
        for easier access to the etcd cluster.
      '';
      type = types.port;
      default = 19100;
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "etcd_backup_";
      inventory_path = "all/etcd-backup.yaml";
    })
  ];
}
