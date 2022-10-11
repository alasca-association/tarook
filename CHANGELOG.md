We currently do not provide proper changelogs because we do not have a proper release management, yet :/ Sorry!

Maybe `git log --no-merges` will help you to get a rough overview of recent changes in the meanwhile.

Nonetheless, as we're having a continuously growing user base, some important notes can be found below:

## Observation of etcd

Our monitoring stack now includes the observation of etcd. To fetch the metrics securely (cert-auth based), a thin socat-based proxy is installed inside the kube-system namespace.

## Support for Kubernetes v1.23

The LCM now supports Kubernetes v1.23.
One can either directly create a new cluster with that version or upgrade an existing one as usual via:

```shell
# Replace the patch version
MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.23.11
```

Further information are given in the [Upgrading Kubernetes documentation](https://yaook.gitlab.io/k8s/operation/upgrading-kubernetes.html).

## config.toml: Introduce the mandatory option `[miscellaneous]/container_runtime`

This must be set to `"docker"` for pre-existing clusters. New clusters
should be set up with `"containerd"`. Migration of pre-existing
clusters from docker to containerd is not yet supported.

## [Replace count with for_each in terraform (!524)](https://gitlab.com/yaook/k8s/-/merge_requests/524)

terraform now uses `for_each` to manage instances which allows the user to delete instances of any index without extraordinary terraform black-magic.
The LCM auto-magically orchestrates the migration.

## [Add action for system updates of initialized nodes (!429)](https://gitlab.com/yaook/k8s/-/merge_requests/429)

The node system updates have been pulled out into a [separate action script](https://yaook.gitlab.io/k8s/operation/actions-references.html#system_update_nodessh).
The reason for that is, that even though one has not set `MANAGED_K8S_RELEASE_THE_KRAKEN`, the cache of the package manager of the host node is updated in stage2 and stage3.
That takes quite some time and is unnecessary as the update itself won't happen.
More rationales are explained in the commit message of e4c622114949a7f5108e8b4fa3d4217dcb1345bc.

## [cluster-repo: Move submodules into dedicated directory (!433)](https://gitlab.com/yaook/k8s/-/merge_requests/433)

We're now moving (git) submodules into a dedicated directory `submodules/`.
For users enabling these, the cluster repository starts to get messy, latest after introducing the option to
   use [customization playbooks](https://yaook.gitlab.io/k8s/design/abstraction-layers.html#customization).

As this is a breaking change, users which use at least one submodule **must** re-execute the [`init.sh`-script](https://yaook.gitlab.io/k8s/operation/actions-references.html#initsh)!
The `init.sh`-script will move your enabled submodules into the `submodules/` directory.
Otherwise at least the symlink to the [`ch-role-users`-role](k8s-base/roles/ch-role-users) will be broken.

> **NOTE:** By re-executing the `init.sh`, the latest `devel` branch of the `managed-k8s`-module will be checked out under normal circumstances!
