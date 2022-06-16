# Backups

> TODO: needs updates and details

Backups should be made of all credentials (certificates), the etcd database and, if necessary, persistent volumes. Backups are useful when, e.g., a K8s upgrade fails or the user accidentally deleted an important resource. A cronjob dumps the etcd database every N minutes and ensures that the number of backup instances is contained. One candidate for managing the backups is borg. 

Automated etcd backups can be configured in [config/config.toml](../usage/cluster-configuration.md#etcd-backup-configuration). To restore the cluster re-run kubeadm with an existing etcd database. The guide for restoration can be found  in the [operations handbook](https://gitlab.cloudandheat.com/operations/operations-handbook/-/blob/master/src/managed-k8s/etcd.md) only accessible by C&H. The process is also available at the official Kubernetes documentation of etcd [here](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#restoring-an-etcd-cluster).
