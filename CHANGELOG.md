# Changelog

## 2020-04-06

* New wireguard user management

  This will automatically and persistently assign IPs to wireguard users, while still allowing dynamic addition and removal of individual and per-cluster users. Per-cluster users are managed in the `config.toml` as before. Company-wide users are managed in the [`wg_user`](https://gitlab.cloudandheat.com/lcm/wg_user/) repository.

  **Migration notes:**

  This requires the [`wg_user`](https://gitlab.cloudandheat.com/lcm/wg_user/) submodule in the cluster repository. You have to add it if you didn’t already and if you’re not using `manage_cluster.sh` (which will add it automatically).

  In addition, you have to remove all `wg_peers` entries which refer to keys already included in the `wg_user` repository from the cluster’s `config.toml`. Those peers may get new IP addresses assigned.

* Support for kube-router instead of flannel.

  Please migrate ASAP. Migration guide in https://gitlab.cloudandheat.com/lcm/managed-k8s/-/merge_requests/53 as well as the commit history.
