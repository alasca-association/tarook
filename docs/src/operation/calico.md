# Calico

- [Calico](#calico)
  - [General Information](#general-information)
  - [Versioning](#versioning)
    - [Manually Upgrade Calico](#manually-upgrade-calico)
  - [Migrate to operator-based Installation](#migrate-to-operator-based-installation)
    - [Configure \& Trigger Migration for existing clusters](#configure-trigger-migration-for-existing-clusters)

## General Information

> **NOTE:**
> Calico versions below `v3.24` can't be set up via the Tigera operator.
> Please update to Kubernetes `v1.24`, which maps Calico `v3.24.5` by default, in advance.

For new clusters, calico will be setup by using the operator-based approach.
More detailed: the [Tigera Calico Operator](https://docs.tigera.io/calico/3.25/getting-started/kubernetes/helm#how-to) is deployed.
The Tigera operator is deployed via `helm`.

It is possible to customize the Calico setup to some extend.
Please check out the [calico configuration section](../usage/cluster-configuration.md#calico-configuration)
for options.

In addition to the Tigera operator which rolls out and sets up the basic Calico installation,
the [Calico API servers](https://docs.tigera.io/calico/3.25/operations/install-apiserver)
are configured and deployed.
This allows to manage Calico-specific resources via `kubectl`.
However, note that this currently does not replace the complete functionality of
[`calicoctl`](https://github.com/projectcalico/calico/tree/master/calicoctl#calicoctl).
Therefore, we're still deploying `calicoctl` on all control-plane nodes.

## Versioning

For each release, Calico published the Kubernetes versions the release has been tested on.
E.g., for Calico v3.25 this section can be found [here](https://docs.tigera.io/calico/3.25/getting-started/kubernetes/requirements#supported-versions).

If not manually adjusted, the Calico version to be deployed is the one mapped to the Kubernetes
version in [`k8s-config`](https://gitlab.com/yaook/k8s/-/blob/devel/k8s-base/roles/k8s-config/defaults/main.yaml).

However, it is possible to configure a custom version via the
[`[kubernetes.network.calico.custom_version]`](../usage/cluster-configuration.md#network-configuration)
variable in the `[kubernetes.network]` section of your cluster-specific `config/config.toml`.

You can choose any version >v3.24 for the operator-based installation,
which is the default for all newly created clusters with Kubernetes >v1.24.

For the manifest-based installation, you have to choose one of the following version:
[`v3.17.1`, `v3.19.0`, `v3.21.6`, `v3.24.5`]
and then [migrate](#migrate-to-operator-based-installation) to the operator-based installation
which is going to be mandatory in the near future anyway.

### Manually Upgrade Calico

Please note what is written in the [versioning section](#versioning) above.

After updating the variable, you then can update calico by executing the following.
Note that this is a (slightly) disruptive action:

```shell
MANAGED_K8S_RELEASE_THE_KRAKEN=true AFLAGS="--diff -t calico" bash managed-k8s/actions/apply-stage3.sh
```

Optionally but recommended,
you can verify the calico functionality afterwards by triggering the test role:

```
AFLAGS="--diff -t check-calico" bash managed-k8s/actions/test.sh
```

## Migrate to operator-based Installation

In the old days, we set up Calico by essentially automating
["Calico - the hard way"](https://docs.tigera.io/calico/3.25/getting-started/kubernetes/hardway/overview)
with additions and customization.
Unfortunately, we customized our Calico installation to such an extend,
that the automated operator migration is not possible
as the Tigera operator is unable to adopt the existing resources.

It is possible to migrate from the manifest-based approach to the operator-based approach
for existing clusters though.

### Configure & Trigger Migration for existing clusters

If you want to postpone migration,
set `kubernetes.network.calico.use_tigera_operator` to `false`
in your `config/config.toml`.

> **NOTE:**
The migration is disruptive.
In-between the removal of the resources of the manifest-based installation
and the deployment and setup of the Tigera operator
which then sets up a new Calico installation on a green field,
it is not possible for new Pods, Services et. al to reach each other.
The existing iptables rules of Kubernetes resources known at the point of time when the migration started,
will still be available.
This will lead to some confusion if a newly created iptables rule conflicts with an existing one,
but the Tigera operator is able to resolve that.
This is, from our point of view, the more gentle migration way.
The alternative would be to clean up all iptables rules on all nodes
when removing the manifest-based installation.
However, that would result in no connectivity at all during migration.

In your `config/config.toml`, set `kubernetes.network.calico.use_tigera_operator` to `true` (default).

If you're running a Kubernetes version below v1.24,
and don't can upgrade to Kubernetes v1.24 before doing the migration,
you have to set a custom calico version `[kubernetes.network.calico.custom_version]`
in your `config/config.toml`
to a version >v3.24.

However, it is recommended to upgrade Kubernetes to v1.24 before doing the migration.

As the migration is disruptive, you must explicitly allow disruption by passing
`MANAGED_K8S_RELEASE_THE_KRAKEN=true`.
The migration can be triggered as followed:

```shell
MANAGED_K8S_RELEASE_THE_KRAKEN=true AFLAGS="--diff -t calico" bash managed-k8s/actions/apply-stage3.sh
```

Hint: During and after the migration you should check the Tigera operator logs.