We currently do not provide proper changelogs because we do not have a proper release management, yet :/ Sorry!

Maybe `git log --no-merges` will help you to get a rough overview of recent changes in the meanwhile.

Nonetheless, as we're having a continuously growing user base, some important notes can be found below:

## 2022-07-19

### [Replace count with for_each in terraform (!524)](https://gitlab.com/yaook/k8s/-/merge_requests/524)

terraform now uses `for_each` to manage instances which allows the user to delete instances of any index without extraordinary terraform black-magic.
The LCM auto-magically orchestrates the migration.

## 2022-02-24

### [Add action for system updates of initialized nodes (!429)](https://gitlab.com/yaook/k8s/-/merge_requests/429)

The node system updates have been pulled out into a [separate action script](https://yaook.gitlab.io/k8s/operation/actions-references.html#system_update_nodessh).
The reason for that is, that even though one has not set `MANAGED_K8S_RELEASE_THE_KRAKEN`, the cache of the package manager of the host node is updated in stage2 and stage3.
That takes quite some time and is unnecessary as the update itself won't happen.
More rationales are explained in the commit message of e4c622114949a7f5108e8b4fa3d4217dcb1345bc.

## 2022-02-11

### [cluster-repo: Move submodules into dedicated directory (!433)](https://gitlab.com/yaook/k8s/-/merge_requests/433)

We're now moving (git) submodules into a dedicated directory `submodules/`.
For users enabling these, the cluster repository starts to get messy, latest after introducing the option to
   use [customization playbooks](https://yaook.gitlab.io/k8s/design/abstraction-layers.html#customization).

As this is a breaking change, users which use at least one submodule **must** re-execute the [`init.sh`-script](https://yaook.gitlab.io/k8s/operation/actions-references.html#initsh)!
The `init.sh`-script will move your enabled submodules into the `submodules/` directory.
Otherwise at least the symlink to the [`ch-role-users`-role](k8s-base/roles/ch-role-users) will be broken.

> **NOTE:** By re-executing the `init.sh`, the latest `devel` branch of the `managed-k8s`-module will be checked out under normal circumstances!
