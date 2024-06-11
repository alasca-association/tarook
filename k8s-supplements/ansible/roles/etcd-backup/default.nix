{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.k8s-service-layer.etcd-backup;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.k8s-service-layer.etcd-backup = mkTopSection {
    enabled = mkEnableOption "Enable etcd-backup";
    schedule = mkOption {
      description = ''
        Configure value for the cron job schedule for etcd backups.
      '';
      type = types.str;
      default = "21 */12 * * *";
    };
    bucket_name = mkOption {
      description = ''
        Name of the s3 bucket to store the backups.
      '';
      type = types.str;
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
      type = types.str;
      default = "yaook/${config.yk8s.vault.cluster_name}/kv";
    };
    vault_path = mkOption {
      description = ''
        Configure the kv2 key under which the credentials are found inside Vault.
        This location is the default location used by import.sh and is recommended.

        The role expects a JSON object with `access_key` and `secret_key` keys,
        containing the corresponding S3 credentials.
      '';
      type = types.str;
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
      type = with types; nullOr str;
      default = null;
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
  config.yk8s.k8s-service-layer.etcd-backup = {
    _ansible_prefix = "etcd_backup_";
    _inventory_path = "all/etcd-backup.yaml";
  };
}
