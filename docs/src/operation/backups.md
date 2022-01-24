# Backups

> TODO: needs updates and details

Backups should be made of all credentials (certificates), the etcd database and, if necessary, persistent volumes. Backups are useful when, e.g., a K8s upgrade fails or the user accidentally deleted an important resource. A cronjob dumps the etcd database every N minutes and ensures that the number of backup instances is contained. One candidate for managing the backups is borg. To restore the cluster re-run kubeadm with an existing etcd database.
