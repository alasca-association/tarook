We currently do not provide proper changelogs because we do not have a proper release management, yet :/ Sorry!

Maybe `git log --no-merges` will help you to get a rough overview of recent changes in the meanwhile.

Nonetheless, as we're having a continuously growing user base, some important notes can be found below:

## 2022-02-11

### [cluster-repo: Move submodules into dedicated directory (!433)](https://gitlab.com/yaook/k8s/-/merge_requests/433)

We're now moving (git) submodules into a dedicated directory `submodules/`.
For users enabling these, the cluster repository starts to get messy, latest after introducing the option to
   use [customization playbooks](https://yaook.gitlab.io/k8s/design/abstraction-layers.html#customization).

As this is a breaking change, users which use at least one submodule **must** re-execute the [`init.sh`-script](https://yaook.gitlab.io/k8s/operation/actions-references.html#initsh)!
The `init.sh`-script will move your enabled submodules into the `submodules/` directory.
Otherwise at least the symlink to the [`ch-role-users`-role](k8s-base/roles/ch-role-users) will be broken.

> **NOTE:** By re-executing the `init.sh`, the latest `devel` branch of the `managed-k8s`-module will be checked out under normal circumstances!
