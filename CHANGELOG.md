We currently do not provide proper changelogs because we do not have a proper release management, yet :/ Sorry!

Maybe `git log --no-merges` will help you to get a rough overview of recent changes in the meanwhile.

Nonetheless, as we're having a continuously growing user base, some important notes can be found below:

## Add support for Kubernetes v1.25

We added support for all patch versions of Kubernetes v1.25.
One can either directly create a new cluster with a patch release of that version or upgrade an existing cluster to one [as usual](https://yaook.gitlab.io/k8s/operation/upgrading-kubernetes.html) via:

```shell
# Replace the patch version
MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.25.10
```

> **NOTE:** By default, the Tigera operator is deployed with Kubernetes v1.25.
> Therefore, during the upgrade from Kubernetes v1.24 to v1.25, the [migration to the Tigera operator](https://yaook.gitlab.io/k8s/operation/calico.html#migrate-to-operator-based-installation)
> will be triggered automatically by default!

## [Add support for Helm-based installation of rook-ceph (!676)](https://gitlab.com/yaook/k8s/-/merge_requests/676)
Starting with rook v1.7, an official Helm chart is provided and has become the
recommended installation method. The charts take care most installation and
upgrade processes. The role rook_v2 includes adds support for the Helm-based
installation as well as a migration path from rook_v1.

In order to migrate, make sure that rook v1.7.11 is installed and healthy, then
set use_helm=true in the k8s-service-layer.rook section and run stage4.

## [GPU: Rework setup and check procedure (!750) · Merge requests · YAOOK / k8s · GitLab](https://gitlab.com/yaook/k8s/-/merge_requests/750)

We reworked the setup and smoke test procedure for GPU nodes to be used inside of Kubernetes [1].
In the last two ShoreLeave-Meetings (our official development) meetings [2] and our IRC-Channel [3]
we asked for feedback if the old procedure is in use in the wild.
As that does not seem to be the case,
we decided to save the overhead of implementing and testing a migration path.
If you have GPU nodes in your cluster and support for these breaks by the reworked code,
please create an issue or consider rebuilding the nodes with the new procedure.

[1] [GPU Support Documentation](./docs/src/operation/gpu-and-vgpu.md#internal-usage)  
[2] https://gitlab.com/yaook/meta#subscribe-to-meetings  
[3] https://gitlab.com/yaook/meta/-/wikis/home#chat

## Change kube-apiserver Service-Account-Issuer
Kube-apiserver now issues service-account tokens with `https://kubernetes.default.svc` as issuer instead of `kubernetes.default.svc`.
Tokens with the old issuer are still considered valid, but should be renewed as this additional support will be dropped in the future.

This change had to be made to make yaook-k8s pass all [k8s-conformance tests](https://github.com/cncf/k8s-conformance/blob/master/instructions.md).

## Drop support for Kubernetes v1.20

We're dropping support for Kubernetes v1.20 as this version is EOL quite some time.
This step has been announced several times in our [public development meeting](https://gitlab.com/yaook/meta#subscribe-to-meetings).

## Drop support for Kubernetes v1.19

We're dropping support for Kubernetes v1.19 as this version is EOL quite some time.
This step has been announced several times in our [public development meeting](https://gitlab.com/yaook/meta#subscribe-to-meetings).

## Implement support for Tigera operator-based Calico installation

Instead of using a customized manifest-based installation method,
we're now switching to an
[operator-based installation](https://docs.tigera.io/calico/3.25/about/) method
based on the Tigera operator.

**Existing clusters must be migrated.**
Please have a look at our [Calico documentation](./docs/src/operation/calico.md)
for further information.

## Support for Kubernetes v1.24

The LCM now supports Kubernetes v1.24.
One can either directly create a new cluster with a patch release of that version or upgrade an existing cluster to one as usual via:

```shell
# Replace the patch version
MANAGED_K8S_RELEASE_THE_KRAKEN=true ./managed-k8s/actions/upgrade.sh 1.24.10
```

> **NOTE:** If you're using docker as CRI,
> you **must** [migrate to containerd](https://yaook.gitlab.io/k8s/operation/migrate-docker-containerd.html)
> in advance.

Further information are given in the [Upgrading Kubernetes documentation](https://yaook.gitlab.io/k8s/operation/upgrading-kubernetes.html).

## Implement automated docker to containerd migration

A migration path to change the container runtime on each node of a cluster from docker to containerd has been added.
More information about this can be found in the [documentation](docs/src/operation/migrate-docker-containerd.md).

## Drop support for kube-router

We're dropping support for kube-router as CNI.
This step has been announced via our usual communication channels months ago.
A migration path from kube-router to calico has been available quite some time and is also removed now.

## Support for Rook 1.7 added

The LCM now supports Rook v1.7.*.
Upgrading is as easy as setting your rook version to 1.7.11, allowing to release the kraken and running stage 4.

## Support for Calico v3.21.6

We now added support for Calico v3.21.6, which is tested against Kubernetes `v1.20, v1.21 and v1.22` by the Calico project team.
We also added the possibility to specify one of our supported Calico versions (`v3.17.1, v3.19.0, v3.21.6`) through a `config.toml` variable: `calico_custom_version`.

## ch-k8s-lbaas now respects NetworkPolicy objects

If you are using NetworkPolicy objects, ch-k8s-lbaas will now interpret them and enforce restrictions on the frontend. That means that if you previously only allowlisted the CIDR in which the lbaas agents themselves reside, your inbound traffic will be dropped now.

You have to add external CIDRs to the network policies as needed to avoid that.

Clusters where NetworkPolicy objects are not in use or where filtering only happens on namespace/pod targets are not affected (as LBaaS wouldn't have worked there anyway, as it needs to be allowlisted in a CIDR already).

## [Add Priority Class to esssential cluster components (!633) · Merge requests · YAOOK / k8s · GitLab](https://gitlab.com/yaook/k8s/-/merge_requests/633)

The [priority classes](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) `system-cluster-critical` and `system-node-critical` have been added to all managed and therefore essential services and components.
There is no switch to avoid that.
For existing clusters, all managed components will therefore be restarted/updated once during the next application of the LCM.
This is considered not disruptive.

## Decoupling thanos and terraform

When enabling thanos, one can now prevent terraform from creating a bucket in the same OpenStack project by setting `manage_thanos_bucket=false` in the `[k8s-service-layer.prometheus]`. Then it's up to the user to manage the bucket by configuring an alternative storage backend.

## OpenStack: Ensure that credentials are used

https://gitlab.com/yaook/k8s/-/merge_requests/625 introduces the role `check-openstack-credentials` which fires a token request against the given Keystone endpoint to ensure that credentials are available. For details, check the commit messages. This sanity check can be skipped by either passing `-e check_openstack_credentials=False` to your call to `ansible-playbook` or by setting `check_openstack_credentials = True` in the `[miscellaneous]` section of your `config.toml`.

## Thanos: Allow alternative object storage backends

By providing `thanos_objectstorage_config_file` one can tell `thanos-{compact,store}` to use a specific (pre-configured) object storage backend (instead of using the bucket the LCM built for you). Please note that the usage of thanos still requires that the OpenStack installation provides a SWIFT backend. [That's a bug.](https://gitlab.com/yaook/k8s/-/issues/356)

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

