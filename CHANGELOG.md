# Changelog

## Unreleased

* **Upgrade to Terraform 0.13**

  From now on you have to use at least Terraform 0.13

## 2020-09-04

* **Unknown**

  Until now there was no release management for that software. If you are going to upgrade from a previous state make sure to check the delta and the consequences of it.

## 2020-04-21

* **Resource Limits**

  There are now resource limits (both CPU and Memory) in place for Rook and Monitoring pods. These Kubernetes-side values impose hard limits on the resources usable by processes. In case of the memory limits, crossing those limitswill cause termination by the OOM killer. In case of the CPU limits, throttling takes place.

  The limits are all configurable via config switches documented in the template configuration.

  **Note:** The limits for the MDS daemon do not take effect unless the filesystem is destroyed and recreated. This is most likely a rook bug, but since we’re not on the most recent stable version, we cannot assess this properly at this time.

  **Note:** The default prometheus memory limit is chosen conservatively; we do not have real numbers on the use and it might be too high or too low. Experimentation with real clusters is required and it’s possible that scaling is needed.

## 2020-04-06

* New wireguard user management

  This will automatically and persistently assign IPs to wireguard users, while still allowing dynamic addition and removal of individual and per-cluster users. Per-cluster users are managed in the `config.toml` as before. Company-wide users are managed in the [`wg_user`](https://gitlab.cloudandheat.com/lcm/wg_user/) repository.

  **Migration notes:**

  This requires the [`wg_user`](https://gitlab.cloudandheat.com/lcm/wg_user/) submodule in the cluster repository. You have to add it if you didn’t already and if you’re not using `manage_cluster.sh` (which will add it automatically).

  In addition, you have to remove all `wg_peers` entries which refer to keys already included in the `wg_user` repository from the cluster’s `config.toml`. Those peers may get new IP addresses assigned.

* Support for kube-router instead of flannel.

  Please migrate ASAP. Migration guide in https://gitlab.cloudandheat.com/lcm/managed-k8s/-/merge_requests/53 as well as the commit history.
