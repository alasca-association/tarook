# Upgrading Rook and Ceph

The following sections describe how an existing rook-based ceph
cluster can be updated.

## Supported rook/ceph versions in mk8s

The following table contains all rook versions that can be configured
as well as the corresponding ceph version that will be deployed.
The mapping of a rook to a ceph version is done in the `k8s-config`
role.

<center>

| rook version | ceph version |
| :----------- | :----------- |
| `v1.2.3`     | `v14.2.5`    |
| `v1.3.11`    | `v14.2.21`   |
| `v1.4.9`     | `v15.2.13`   |
| `v1.5.12`    | `v15.2.13`   |
| `v1.6.7`     | `v16.2.5`    |

</center>

## A word of warning / Things to be considered

> **WARNING:** Upgrading a Rook cluster is not without risk. There may
> be unexpected issues or obstacles that damage the integrity and
> health of your storage cluster, including data loss. Only proceed
> with this guide if you are comfortable with that.

> The Rook cluster’s storage may be unavailable for short periods
> during the upgrade process for both Rook operator updates and for
> Ceph version updates.

Rook upgrades can only be performed from any official minor release to
the **next** minor release.
This means you can only update from e.g. `v1.2.* --> v1.3.*`,
`v1.3.* --> v1.4.*`, etc.

Downgrades are theoretically possible, but we do not (want to) cover
automated downgrades.

## How to update an existing Cluster

The rook version to be deployed can be defined in your managed-k8s
cluster configuration via the variable `version` in the
`[k8s-service-layer.rook]` section.

This variable currently defaults to `v1.2.3` (which is mapped to ceph `v14.2.5`).

### Steps to perform an upgrade

1. Make sure you have read this document and checked the `Considerations`
   section in the [Rook Upgrade Docs](https://rook.io/docs/rook/v1.2/ceph-upgrade.html#considerations).
   (Please select your target version on the Documentation page)

2. Determine which rook version is currently deployed. It should be
   the currently configured rook version in your managed-k8s cluster
   configuration file. To be sure you can check the actual deployed
   version with the following commands:
    ```shell
    # Determine the actual rook-ceph-operator Pod name
    POD_NAME=$(kubectl -n rook-ceph get pod \
    -o custom-columns=name:.metadata.name --no-headers \
    | grep rook-ceph-operator)
    # Get the configured rook version
    kubectl -n rook-ceph get pod ${POD_NAME} \
    -o jsonpath='{.spec.containers[0].image}'
    ```

3. (Optional)

   Determine which ceph version is currently deployed:
   ```shell
   kubectl -n rook-ceph get CephCluster rook-ceph \
   -o jsonpath='{.spec.cephVersion.image}'
   ```

4. Depending on the currently deployed rook version, determine the
   *next* (supported) minor release. The managed-k8s cluster
   configuration template states all supported versions. If in doubt,
   all supported rook releases are also stated in the `k8s-config`
   role as well as in the `k8s-rook` role (and in this doc file).

5. Set `version` in the `[k8s-service-layer.rook]` section to the
   *next* (supported) minor release of rook.
   ```toml
   [...]
   [k8s-service-layer.rook]
   [...]
   # Enable rook deployment
   rook = true
   #
   # rook version. Currently we do support:
   # v1.2.3, v1.3.11, v1.4.9, v1.5.12, v1.6.7
   rook_version = "v1.6.7"
   [...]
   ```

6. Execute the `toml_helper`
   ```shell
   python3 managed-k8s/jenkins/toml_helper.py
   ```

7. Execute `stage3`, or at least the `k8s-rook` tasks. As the upgrade is
   disruptive (at least for a short amount of time) disruption needs to be enabled.
   ```shell
   # Trigger stage 3
   MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-stage3.sh
   # Trigger only k8s-rook
   export AFLAGS='--diff --tags mk8s-sl/rook'
   MANAGED_K8S_RELEASE_THE_KRAKEN=true bash managed-k8s/actions/apply-stage3.sh
   ```

8. Get yourself your favorite (non-alcoholic) drink and watch with
   fascinating enthusiasm how your rook-based ceph cluster gets upgraded.
   (Can take several minutes (up to hours)).

9. After the upgrade has been proceeded, check that your managed-k8s
    cluster still is in a sane state via the smoke tests.
    ```shell
    bash managed-k8s/actions/test.sh
    ```

10. Continue with steps `{1,3..11}` until you have reached your final
    target rook version.

11. Celebrate that everything worked out `ᕕ( ᐛ )ᕗ`


### Updating rook manually

Currently, there is only one major release of rook.

Updating rook to a new patch version is fairly easy and fully automated
by rook itself. You can simply patch the image version of the
`rook-ceph-operator`.

```shell
# Example for the update of rook
# to a new (fictional) patch version of v1.7.*
kubectl -n rook-ceph set image deploy/rook-ceph-operator rook-ceph-operator=rook/ceph:v1.7.42
```

Updating rook to a new minor release usually requires additional steps.
These steps are described in the corresponding [upgrade section of the rook Docs](https://rook.io/docs/rook/v1.2/ceph-upgrade.html#upgrading-from-v11-to-v12)

### Updating ceph manually

Updating ceph is fully automated by rook.
As long as the currently deployed `rook-ceph-operator` supports the
configured ceph version, the operator will perform the update without
the need of further intervention
Just ensure that the ceph version really is supported by the currently
deployed rook version.

```shell
# Example for the update of ceph to
# a new (fictional) release v17.2.42
kubectl -n rook-ceph patch CephCluster rook-ceph --type=merge -p "{\"spec\": {\"cephVersion\": {\"image\": \"ceph/ceph:v17.2.42\"}}}"
```

## Adding/Implementing support for a new rook/ceph release to managed-k8s

Adding support for a new rook or ceph release may be accomplished by
with the following steps.

### Adding support for a new rook release

Check for new releases in the [rook Github repository](https://github.com/rook/rook/releases).
Read the corresponding upgrade page at the [rook Docs](https://rook.io/docs/rook/).
**Especially check the `Considerations` section there**.

* Download the source code of the new rook release from the [rook Github repository](https://github.com/rook/rook/releases)
  * The source code contains the updated manifests in `cluster/examples/kubernetes/ceph/`
* Create a new subdirectory for the manifest templates in the `k8s-rook`
  role (e.g. `v1.42`)
* Copy the necessary templates to the subdirectory
  * **You need to adjust/modify these manifests before applying them**
  * `diff` is your friend :)
* Implement the actual upgrade steps described in the [rook Docs](https://rook.io/docs/rook/)
  into a new task file which you should call `upgrade_rook_from_v1.42.yaml`
  * Please also include the cluster health verification task prior and subsequent
    to the actual upgrade steps. As the `ceph status` update can slightly
    differ from release to release, you may need to adjust the cluster
    health verification tasks. You have to ensure backwards compatibility
    when adjusting these tasks.
* Make sure your implemented upgrade tasks are included at the right place
  and under the correct circumstances in `version_checks.yaml`
* Add the newly supported version to `rook_supported_releases` in `k8s-rook`
* Add the newly supported version (and the corresponding ceph version)
  to the `rook_ceph_version_map` in `k8s-config`
* Adjust the comment about supported versions in the configuration template
* (Update the CI configuration)
* **Test your changes**
  * Configure the new rook version in your managed-k8s cluster configuration
  * Make sure the correct upgrade tasks are included
  * The `rook-ceph-operator` logs are very helpful to observe the upgrade
  * Execute the smoke tests

### Adding support for a new ceph release

If you notice that a new ceph release is available,
I do not recommend modifying/updating the mapped ceph version of an already existing
rook release in `k8s-config`.
This would trigger existing clusters to perform a ceph upgrade once the change is merged.

Rook is getting patch releases on a relatively frequent basis.
If a new patch version of rook is released, you can add it to the supported releases map
in `k8s-config` along with the new ceph version you want to have support for.
Patch version upgrades of rook do not require additional steps.
In other words: Once a ceph release is bound to a rook release, do not change that.
This way we ensure that existing clusters will not be accidentally upgraded
(to a new ceph release).

## References

* [Rook-Ceph Upgrade Docs `v1.2`](https://rook.io/docs/rook/v1.2/ceph-upgrade)
* [Rook-Ceph Upgrade Docs `v1.3`](https://rook.io/docs/rook/v1.3/ceph-upgrade)
* [Rook-Ceph Upgrade Docs `v1.4`](https://rook.io/docs/rook/v1.4/ceph-upgrade)
* [Rook-Ceph Upgrade Docs `v1.5`](https://rook.io/docs/rook/v1.5/ceph-upgrade)
* [Rook-Ceph Upgrade Docs `v1.6`](https://rook.io/docs/rook/v1.6/ceph-upgrade)
* [Rook Repository (Github)](https://github.com/rook/rook)
* [Ceph Docker Images](https://hub.docker.com/r/ceph/ceph)
* [Ceph Health Checks Docs](https://docs.ceph.com/en/latest/rados/operations/health-checks/)
