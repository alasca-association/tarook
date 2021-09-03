# Rook-based Ceph Storage

We offer rook-based ceph storage in the k8s cluster. The storage can be used
as block storage or as shared filesystem.

## "Good To Know" / "Gotchas"

- We configure the cluster to use Cinder CSI volumes as backing storage. The
  volumes are already replicated on our OpenStack’s Ceph level, so we set the
  pool size to 1 (= one replica only) in the Rook cluster.

- Cinder volumes are numbered in rook (e.g. `cinder-2-ceph-data`). The numbering
  does *not always* correspond to the OSD number using that volume! This is
  important when debugging OSD issues and when removing OSDs and their storage
  especially.

- Adding volumes can cause the worker instance to crash with a kernel panic due
  to a known kernel bug with a race condition when detaching the Cinder volume
  from the instance.

- To access ceph tools, run:

  ```console
  $ kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
  ```

- Rook stores information about the provisioning state of volumes in ConfigMap
  objects while the provisioning hasn’t completed yet. When removing a
  provisioning job half way through, it is important to also clean up the
  corresponding ConfigMap object, otherwise the operator will hang.

- The ceph mons use the `local-storage` StorageClass which is a fancy version of `hostPath` and has the advantage of "binding" a pod to a node. `local-storage` works through a controller that presents disks (or bind-mounts of directories, as in our case) as PVs to K8s. The controller also attaches PVCs to these PVs.

- Note that it's _usually_ safe to delete a ceph mon and its PVC if at least one healthy mon remains. To be on the safe side, make sure the quorum is `> floor(mons / 2).`

## Administrative tasks

### Reducing the number of OSDs

If the load on the meta machines is too high because of the number of OSDs,
the number of OSDs can be reduced losslessly. This requires a few steps and
great care, but it is possible.

#### Prerequisites

- You need a shell inside the Ceph toolbox. You can open such a shell with:

  ```console
  $ kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
  ```

- The ceph cluster must be healthy (refer to [Cluster Health Verification](https://rook.io/docs/rook/v1.2/ceph-upgrade.html#health-verification)).

#### Remove an OSD without data loss

The following procedure was tested and verified in a test cluster with 6 OSDs.
To check that no data loss occurs, a volume was created with 8 GiB of data on
it. 4 GiB were zeroes and 4 GiB were random numbers. The data was validated
after each step against SHA256 checksums without any caches.

During creation of the data, it was ensured by watching the output of
`ceph osd df` that all OSDs got a share of the data to prevent a false negative.
In addition, the procedure was repeated three times.

1. Check the current disk usage of the OSDs:

   ```console
   toolbox# ceph osd df
   ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA    OMAP META  AVAIL   %USE VAR  PGS STATUS
    0   hdd 0.08690  1.00000  89 GiB 5.0 GiB 4.0 GiB  0 B 1 GiB  84 GiB 5.59 1.35   6     up
    2   hdd 0.08690  1.00000  89 GiB 5.2 GiB 4.2 GiB  0 B 1 GiB  84 GiB 5.83 1.41   7     up
    1   hdd 0.08690  1.00000  89 GiB 3.0 GiB 2.0 GiB  0 B 1 GiB  86 GiB 3.34 0.81   2     up
    3   hdd 0.08690  1.00000  89 GiB 4.9 GiB 3.9 GiB  0 B 1 GiB  84 GiB 5.46 1.32   4     up
    4   hdd 0.08690  1.00000  89 GiB 1.0 GiB 4.6 MiB  0 B 1 GiB  88 GiB 1.13 0.27   3     up
    5   hdd 0.08690  1.00000  89 GiB 3.0 GiB 2.0 GiB  0 B 1 GiB  86 GiB 3.42 0.83   2     up
                       TOTAL 534 GiB  22 GiB  16 GiB  0 B 6 GiB 512 GiB 4.13
   MIN/MAX VAR: 0.27/1.41  STDDEV: 1.68
   ```

   In this example, we have six OSDs. Most of them have around 2.2 GiB of data
   on them. One has only 1.0 GiB of data (osd.0) and one has 5.6 GiB of data
   (osd.3).

2. Find the OSD to remove. You can only remove the OSD with the highest-numbered
   cinder volume PVC.

   **Note:** The numbering of the PVCs and OSDs is **not** equal. That means
   that OSD 0 may use volume 3 and OSD 3 may use volume 2 and OSD 2 may use
   volume 0. You *always* have to discover the used volume using the following
   procedure.

   First list all the OSD PVCs:

   ```console
   $ kubectl -n rook-ceph get pvc -l ceph.rook.io/DeviceSet=cinder
   NAME                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
   cinder-0-ceph-data-v6grl   Bound    pvc-27cccd47-5443-462b-b8d9-fe3192945223   90Gi       RWO            csi-sc-cinderplugin   134m
   cinder-1-ceph-data-8hd8s   Bound    pvc-83c714af-617b-4834-b9be-30f9b9f4e96f   90Gi       RWO            csi-sc-cinderplugin   134m
   cinder-2-ceph-data-n6gdx   Bound    pvc-9c304b41-bb0c-4a84-8481-3990f5f34618   90Gi       RWO            csi-sc-cinderplugin   134m
   cinder-3-ceph-data-446b4   Bound    pvc-3929dde6-eb35-402f-a4ff-07c00db59447   90Gi       RWO            csi-sc-cinderplugin   134m
   cinder-4-ceph-data-hjwmt   Bound    pvc-3f4f4a66-692f-4cd6-8f12-e55244da62df   90Gi       RWO            csi-sc-cinderplugin   134m
   cinder-5-ceph-data-bwctn   Bound    pvc-07400ac2-bc0c-4f97-999f-d50ba81b33ec   90Gi       RWO            csi-sc-cinderplugin   134m
   ```

   Then pick the one with the highest number in the name, in this example this
   is `cinder-5-ceph-data-bwctn`

   ```console
   $ kubectl -n rook-ceph describe pvc cinder-5-ceph-data-bwctn
   […]
   Mounted By:    rook-ceph-osd-5-c6d577548-vpscr
                  rook-ceph-osd-prepare-cinder-5-ceph-data-bwctn-89sm8
   […]
   ```

   This gives you the OSD ID of the OSD using this volume. In this example,
   the OSD ID is the same as the volume index, but you *can not rely on this*!

   In the following, we’ll refer to `osd.5` by `$name`, to `5` by `$id`
   (ceph lingo) and to `cinder-5-ceph-data-bwctn` by `$volume`.

   Before proceeding, check that there is enough space. For that, at least the
   amount of `DATA` of the OSD to remove needs to be `AVAIL` on the other OSDs
   combined. Due to the way ceph balances data, it is better if most OSDs can
   take most of the data of the OSD you remove.

   I’m not sure what’s going to happen if the data cannot be rebalanced, but
   I assume that (a) it will not cause data loss if you abort before removing
   the OSD and (b) ceph will tell you.

3. Set the weight of the OSD to 0. This makes ceph redistribute the data on that
   OSD to the other OSDs:

   ```console
   toolbox# ceph osd crush reweight $name 0
   ```

   **Note:** There is [a difference between `ceph osd crush reweight` and `ceph osd reweight`](https://ceph.io/geen-categorie/difference-between-ceph-osd-reweight-and-ceph-osd-crush-reweight/). `ceph osd crush reweight` is a permanent weighting
   measure, while `ceph osd reweight` is a temporary measure which gets lost on
   a in/out cycle of an OSD.

4. Wait for the migration to finish.

   You can run `watch ceph osd df` as well as `watch ceph -s` to observe the
   migration status; the former will show how the number of placement groups
   (`PGS` column) for that OSD decreases, while the latter will show the status
   of the cluster overall.

   The migration is over when:

   - The number of placement groups for your victim OSD is 0
   - All placement groups show as active+clean in `ceph -s`

   Note: the `RAW USE` column of the `ceph osd df` output does not decrease for
   some reason. The column to look at is `DATA`, which should reduce to
   something in the order of `10 MiB`.

   ```console
   toolbox# ceph osd df
   ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA    OMAP META  AVAIL   %USE VAR  PGS STATUS
    0   hdd 0.08690  1.00000  89 GiB 5.0 GiB 4.0 GiB  0 B 1 GiB  84 GiB 5.59 1.24   7     up
    2   hdd 0.08690  1.00000  89 GiB 7.2 GiB 6.2 GiB  0 B 1 GiB  82 GiB 8.12 1.80   8     up
    1   hdd 0.08690  1.00000  89 GiB 3.0 GiB 2.0 GiB  0 B 1 GiB  86 GiB 3.34 0.74   2     up
    3   hdd 0.08690  1.00000  89 GiB 4.9 GiB 3.9 GiB  0 B 1 GiB  84 GiB 5.46 1.21   4     up
    4   hdd 0.08690  1.00000  89 GiB 1.0 GiB 5.2 MiB  0 B 1 GiB  88 GiB 1.13 0.25   3     up
    5   hdd       0  1.00000  89 GiB 3.0 GiB 1.9 GiB  0 B 1 GiB  86 GiB 3.42 0.76   0     up
                       TOTAL 534 GiB  24 GiB  18 GiB  0 B 6 GiB 510 GiB 4.51
   MIN/MAX VAR: 0.25/1.80  STDDEV: 2.20
   toolbox# ceph -s
     cluster:
       id:     9c61da6b-67e9-4acd-a25c-929db5cbb3f2
       health: HEALTH_OK

     services:
       mon: 3 daemons, quorum a,b,c (age 2h)
       mgr: a(active, since 2h)
       mds: ceph-fs:1 {0=ceph-fs-a=up:active} 1 up:standby-replay
       osd: 6 osds: 6 up (since 2h), 6 in (since 2h)

     data:
       pools:   3 pools, 24 pgs
       objects: 4.21k objects, 16 GiB
       usage:   24 GiB used, 510 GiB / 534 GiB avail
       pgs:     24 active+clean

     io:
       client:   1.2 KiB/s rd, 2 op/s rd, 0 op/s wr
   ```

5. Mark the OSD as out.

   ```console
   toolbox# ceph osd out $name
   ```

   `ceph osd df` should now show it with all zeros, and `ceph -s` should still
   be `HEALTH_OK` with all placement groups being `active+clean`, since the data
   has been moved elsewhere. **If this is not the case** abort now and seek help
   immediately!

   ```console
   toolbox# ceph -s
   […]
     services:
       mon: 3 daemons, quorum a,b,c (age 2h)
       mgr: a(active, since 2h)
       mds: ceph-fs:1 {0=ceph-fs-a=up:active} 1 up:standby-replay
       osd: 6 osds: 6 up (since 2h), 5 in (since 7s)

     data:
       pools:   3 pools, 24 pgs
       objects: 4.21k objects, 16 GiB
       usage:   22 GiB used, 512 GiB / 534 GiB avail
       pgs:     24 active+clean
   […]
   ```

6. Reduce the number of OSDs in the Cluster CRD. Update the `config.toml` of the
   cluster by decreasing `ansible.03_final.group_vars.all.rook_nosds` by one.

   Run the `toml_helper.py` and execute stage three (possibly with `-t rook` to
   only apply rook changes).

7. Wait until the cluster has updated. Watch the output of:

   ```console
   $ kubectl -n rook-ceph get cephcluster rook-ceph -o yaml | tail
   ```

   until the state has changed to Updating and back to Created.

8. Wait until the operator has deleted the OSD pod.

   ```
   $ watch kubectl -n rook-ceph get pod -l ceph-osd-id=$id
   ```

   This command should print "No resources found in rook-ceph namespace.".

   (Rook will auto-delete OSDs which are marked as out and have no placement
   groups.)

9. Purge the OSD. *If the data has not been moved, data loss will occur here!*

   ```console
   toolbox# ceph osd purge $name
   ```

   **Note:** You do not need `--yes-i-really-mean-it` since all data was moved
   to another device. If ceph asks you for `--yes-i-really-mean-it` something is
   wrong!

   `ceph osd df` should not list the OSD anymore, and `ceph -s` should say that
   there are now only 5 OSDs (if you started out with 6), all of which should be
   up and in.

   ```console
   toolbox# ceph osd df
   ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA    OMAP META  AVAIL   %USE VAR  PGS STATUS
    0   hdd 0.08690  1.00000  89 GiB 5.0 GiB 4.0 GiB  0 B 1 GiB  84 GiB 5.59 1.18   7     up
    2   hdd 0.08690  1.00000  89 GiB 7.2 GiB 6.2 GiB  0 B 1 GiB  82 GiB 8.12 1.72   8     up
    1   hdd 0.08690  1.00000  89 GiB 3.0 GiB 2.0 GiB  0 B 1 GiB  86 GiB 3.34 0.71   2     up
    3   hdd 0.08690  1.00000  89 GiB 4.9 GiB 3.9 GiB  0 B 1 GiB  84 GiB 5.46 1.16   4     up
    4   hdd 0.08690  1.00000  89 GiB 1.0 GiB 5.6 MiB  0 B 1 GiB  88 GiB 1.13 0.24   3     up
                       TOTAL 445 GiB  21 GiB  16 GiB  0 B 5 GiB 424 GiB 4.73
   MIN/MAX VAR: 0.24/1.72  STDDEV: 2.35
   toolbox# ceph -s
     cluster:
       id:     9c61da6b-67e9-4acd-a25c-929db5cbb3f2
       health: HEALTH_OK

     services:
       mon: 3 daemons, quorum a,b,c (age 2h)
       mgr: a(active, since 2h)
       mds: ceph-fs:1 {0=ceph-fs-a=up:active} 1 up:standby-replay
       osd: 5 osds: 5 up (since 2m), 5 in (since 5m)

     data:
       pools:   3 pools, 24 pgs
       objects: 4.21k objects, 16 GiB
       usage:   21 GiB used, 424 GiB / 445 GiB avail
       pgs:     24 active+clean

     io:
       client:   1.2 KiB/s rd, 2 op/s rd, 0 op/s wr
   ```

10. Delete the preparation job and the PVC:

    ```console
    $ kubectl -n rook-ceph delete job rook-ceph-osd-prepare-$volume
    $ kubectl -n rook-ceph delete pvc $volume
    ```

    Verify that the volume is gone with `kubectl get pvc -n rook-ceph` and in
    openstack.

Congratulations, you now have one OSD less.


### Change the size of an OSD

#### Prerequisites

- You need a shell inside the Ceph toolbox. You can open such a shell with:

  ```console
  $ kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
  ```

- The ceph cluster must be healthy.

#### Change the size of a single OSD

In theory, there are two ways to go about this. In general, the plan is to
increase the OSD size in the cluster configuration and then substitute an
existing OSD. This can be done by either first removing the existing OSD or
by first adding a new OSD.

It is important to remember the restrictions around removal of OSDs: only the
OSD on the highest numbered volume can be permanently removed from the cluster;
any other OSD would be recreated by the operator, despite a reduced OSD count.

This makes it impossible to first add a larger OSD and then (permanently) remove
a smaller OSD: the newly added larger OSD would have the highest numbered
volume, and would thus be the only OSD you can permanently remove from the
cluster.

Thus, the only feasible way is to first remove any OSD and have the operator
replace it with a larger one. Note that this replacement is exactly the effect
which prevents us from permanently removing any OSD except the one on the
highest numbered volume.

If you do not have enough space in the cluster to buffer away the data of an
OSD, you can temporarily increase the OSD count by one and later remove that
newly created OSD.

Note that all of this applies in the same way to resizing an OSD to a smaller
volume size and to resizing many OSDs (though you probably shouldn’t resize
many at once, for your own cognitive good).

The steps are in many places very similar to removing an OSD, but since we don’t
want to change the overall amount of OSDs, we’ll never decrease the OSD count.

**Beware:** This process will create and attach Cinder Volumes. Due to a known
kernel bug, this may crash the Ceph workers. Ceph will recover from this,
however, it may lead to temporarily unavailable data.

1. Ensure that the cluster is healthy and pick a victim OSD to remove:

   ```console
   toolbox# ceph osd df
   ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA    OMAP   META     AVAIL   %USE VAR  PGS STATUS
    0   hdd 0.08690  1.00000  89 GiB 7.5 GiB 6.5 GiB    0 B    1 GiB  81 GiB 8.47 1.19  18     up
    2   hdd 0.08690  1.00000  89 GiB 6.1 GiB 5.1 GiB 20 KiB 1024 MiB  83 GiB 6.80 0.95  18     up
    1   hdd 0.08690  1.00000  89 GiB 5.5 GiB 4.5 GiB 24 KiB 1024 MiB  84 GiB 6.16 0.86  12     up
                       TOTAL 267 GiB  19 GiB  16 GiB 44 KiB  3.0 GiB 248 GiB 7.14
   MIN/MAX VAR: 0.86/1.19  STDDEV: 0.98
   toolbox# ceph -s
     cluster:
       id:     9c61da6b-67e9-4acd-a25c-929db5cbb3f2
       health: HEALTH_WARN
               3 slow ops, oldest one blocked for 512 sec, mon.c has slow ops

     services:
       mon: 3 daemons, quorum a,b,c (age 8s)
       mgr: a(active, since 32m)
       mds: ceph-fs:1 {0=ceph-fs-a=up:active} 1 up:standby-replay
       osd: 3 osds: 3 up (since 29m), 3 in (since 44m)

     data:
       pools:   3 pools, 48 pgs
       objects: 4.21k objects, 16 GiB
       usage:   19 GiB used, 248 GiB / 267 GiB avail
       pgs:     48 active+clean

     io:
       client:   1.2 KiB/s rd, 2 op/s rd, 0 op/s wr
   ```

   Pick one of the OSDs. In this example, we’ll "resize" the OSD with ID 2.

   We need to find the volume which the OSD uses, which we do with:

   ```console
   $ kubectl -n rook-ceph describe pod -l ceph-osd-id=2
   […]
     cinder-1-ceph-data-8hd8s:
       Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
       ClaimName:  cinder-1-ceph-data-8hd8s
       ReadOnly:   false
   […]
   ```

   `$id` shall now refer to `2`, `$name` shall refer to `osd.2`, `$volume` shall
   refer to `cinder-1-ceph-data-8hd8s`.

   (This is also an excellent example of OSD IDs not mapping 1:1 to volume
   indices.)

2. Set the new target volume size. Update the `config.toml` of kubernetes
   cluster by setting `ansible.03_final.group_vars.all.rook_osd_volume_size`
   to the new desired size.

   Run the `toml_helper.py` and apply the changes by running ansible stage 3
   (possibly with `-t rook` to only apply the rook changes).

3. Evict all data from the victim OSD.

   ```console
   toolbox# ceph osd crush reweight $name 0
   ```

4. Wait for the migration to finish.

   You can run `watch ceph osd df` as well as `watch ceph -s` to observe the
   migration status; the former will show how the number of placement groups
   (`PGS` column) for that OSD decreases, while the latter will show the status
   of the cluster overall.

   The migration is over when:

   - The number of placement groups for your victim OSD is 0
   - All placement groups show as active+clean in `ceph -s`

   Note: the `RAW USE` column of the `ceph osd df` output does not decrease for
   some reason. The column to look at is `DATA`, which should reduce to
   something in the order of `10 MiB`.

   ```console
   toolbox# ceph osd df
   ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA    OMAP   META     AVAIL   %USE  VAR  PGS STATUS
    0   hdd 0.08690  1.00000  89 GiB  11 GiB 9.7 GiB    0 B    1 GiB  78 GiB 11.97 1.46  29     up
    2   hdd       0  1.00000  89 GiB 3.0 GiB  24 MiB 20 KiB 1024 MiB  86 GiB  3.39 0.41   0     up
    1   hdd 0.08690  1.00000  89 GiB 8.3 GiB 7.3 GiB 24 KiB 1024 MiB  81 GiB  9.27 1.13  19     up
                       TOTAL 267 GiB  22 GiB  17 GiB 44 KiB  3.0 GiB 245 GiB  8.21
   MIN/MAX VAR: 0.41/1.46  STDDEV: 3.58
   toolbox# ceph -s
     cluster:
       id:     9c61da6b-67e9-4acd-a25c-929db5cbb3f2
       health: HEALTH_OK

     services:
       mon: 3 daemons, quorum a,b,c (age 9m)
       mgr: a(active, since 41m)
       mds: ceph-fs:1 {0=ceph-fs-a=up:active} 1 up:standby-replay
       osd: 3 osds: 3 up (since 38m), 3 in (since 2m)

     data:
       pools:   3 pools, 48 pgs
       objects: 4.21k objects, 16 GiB
       usage:   21 GiB used, 246 GiB / 267 GiB avail
       pgs:     48 active+clean

     io:
       client:   852 B/s rd, 1 op/s rd, 0 op/s wr
   ```

5. Mark the OSD as out.

   ```console
   toolbox# ceph osd out $name
   ```

   `ceph osd df` should now show it with all zeros, and `ceph -s` should still
   be `HEALTH_OK` with all placement groups being `active+clean`, since the data
   has been moved elsewhere. **If this is not the case** abort now and seek help
   immediately!

   ```console
   toolbox# ceph -s
   […]
     services:
       mon: 3 daemons, quorum a,b,c (age 10m)
       mgr: a(active, since 42m)
       mds: ceph-fs:1 {0=ceph-fs-a=up:active} 1 up:standby-replay
       osd: 3 osds: 3 up (since 39m), 2 in (since 22s)

     data:
       pools:   3 pools, 48 pgs
       objects: 4.21k objects, 16 GiB
       usage:   21 GiB used, 246 GiB / 267 GiB avail
       pgs:     48 active+clean
   […]
   ```

6. Restart the operator to trigger the removal of the evicted OSD:

   ```console
   $ kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas 0
   $ sleep 5
   $ kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas 1
   ```

7. Wait until the operator has deleted the OSD pod (should be at most 10
   minutes).

   ```
   $ watch kubectl -n rook-ceph get pod -l ceph-osd-id=$id
   ```

   This command should print "No resources found in rook-ceph namespace.".

   (Rook will auto-delete OSDs which are marked as out and have no placement
   groups.)

8. Purge the OSD. *If the data has not been moved, data loss will occur here!*

   ```console
   toolbox# ceph osd purge $name
   ```

   **Note:** You do not need `--yes-i-really-mean-it` since all data was moved
   to another device. If ceph asks you for `--yes-i-really-mean-it` something is
   wrong!

   `ceph osd df` should not list the OSD anymore, and `ceph -s` should say that
   there are now only 2 OSDs (if you started out with 3), all of which should be
   up and in.

9. Delete the preparation job and the PVC.

   **Caution:** Deleting the wrong job + pvc will inevitably lead to loss of
   data! Double-check that you’re killing the correct volume by first running:

   ```console
   $ kubectl -n rook-ceph describe pvc $volume
   ```

   The `MountedBy:` line should only list a single user, which is
   `rook-ceph-osd-prepare-$volume-$suffix` (where `$suffix` is a random thing).

   Once you’ve verified that, you can delete the job and the PVC:

   ```console
   $ kubectl -n rook-ceph delete job rook-ceph-osd-prepare-$volume
   $ kubectl -n rook-ceph delete pvc $volume
   ```

   Verify that the volume is gone with `kubectl get pvc -n rook-ceph` and in
   openstack.

10. Restart the operator to trigger re-creation of the OSD.

    ```console
    $ kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas 0
    $ sleep 5
    $ kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas 1
    ```

    You can observe progress by watching the pod list and `ceph osd df`. The
    newly created volume (`kubectl -n rook-ceph get pvc`) should have the new
    size.

    The process is done when you see:

    - all OSDs in `ceph -s` as up and in, and
    - all placement groups as `active+clean`

    ```console
    toolbox# ceph osd df
    ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA    OMAP   META     AVAIL   %USE VAR  PGS STATUS
     2   hdd 0.18459  1.00000 189 GiB 9.9 GiB 8.9 GiB    0 B    1 GiB 179 GiB 5.25 0.91  27     up
     0   hdd 0.08690  1.00000  89 GiB 6.2 GiB 5.2 GiB    0 B    1 GiB  83 GiB 6.92 1.20  14     up
     1   hdd 0.08690  1.00000  89 GiB 5.0 GiB 2.0 GiB 44 KiB 1024 MiB  84 GiB 5.66 0.98   7     up
                        TOTAL 367 GiB  21 GiB  16 GiB 44 KiB  3.0 GiB 346 GiB 5.75
    MIN/MAX VAR: 0.91/1.20  STDDEV: 0.73
    toolbox# ceph -s
      cluster:
        id:     9c61da6b-67e9-4acd-a25c-929db5cbb3f2
        health: HEALTH_OK

      services:
        mon: 3 daemons, quorum a,b,c (age 27s)
        mgr: a(active, since 12m)
        mds: ceph-fs:1 {0=ceph-fs-a=up:active} 1 up:standby-replay
        osd: 3 osds: 3 up (since 12m), 3 in (since 12m)

      data:
        pools:   3 pools, 48 pgs
        objects: 4.21k objects, 16 GiB
        usage:   21 GiB used, 346 GiB / 367 GiB avail
        pgs:     48 active+clean

      io:
        client:   853 B/s rd, 1 op/s rd, 0 op/s wr
    ```

## Initial testing

### Issues

- PVCs do not seem to get deleted when the cluster is deleted

### Resilience testing

Executive Summary:

- I was not able to put the cluster in a state which caused permanent data loss
- All scenarios end, after a while, with Ceph being fully operational

#### Scenario 1: systemctl reboot on a node with 1 OSD and 1 Mon

Scenario/Execution:

- Have containers using the Ceph cluster (via RBD and CephFS volumes) constantly write and check data
- All pools without redundancy
- Pick a node with just an OSD and a Mon and reboot it

Effect:

- Writers stall while the cluster is reconfiguring
- OSD is migrated away from the rebooted node as soon as it comes up
- Mon is restarted sooner(?)

#### Scenario 2: kubectl drain --ignore-daemonsets --delete-local-data on a node with ALL the OSDs

##### Part 1

Scenario/Execution:

- Have containers using the Ceph cluster (via RBD and CephFS volumes) constantly write and check data
- All pools without redundancy
- OSDs are (for some reason) all scheduled to the same node
- kubectl drain that node

Effect:

- Writers stall while the cluster is reconfiguring
- OSDs are rescheduled to other nodes immediately-ish
- Mon is not rescheduled (since we only have three nodes and they’re configured with anti-affinity)
- Writers resume as soon as OSDs are up
- Cluster ends in HEALTH_WARN due to missing Mon

##### Part 2

Execution:

- kubectl uncordon the drained node

Effect:

- No effect on the writers
- Mon is rescheduled to the fresh node
- Cluster is in HEALTH_WARN due to "2 daemons have recently crashed". I’m not being gentle to this thing :>

#### Scenario 3: Hard-reset a node with 1 OSD and 1 Mon

Scenario/Execution:

- Have containers using the Ceph cluster (via RBD and CephFS volumes) constantly write and check data
- All pools without redundancy
- Pick a node with just an OSD and a Mon and hard-reset it using OpenStack

Effect:

- Writers stall while OSD is unavailable
-
    ```
            health: HEALTH_WARN
            insufficient standby MDS daemons available
            1 MDSs report slow metadata IOs
            1 osds down
            1 host (1 osds) down
            no active mgr
            2 daemons have recently crashed
            1/3 mons down, quorum a,b
    ```
    moohahaha

- OSD is *not* rescheduled to another node. Probably too quick for rook to act?
- No data loss AFAICT
- mon failed to re-join quorum for minutes
- deleted the pod, which did not seem to help
- however, it joined quorum after four more minutes. loop of:

    ```
    debug 2020-02-06 07:46:56.889 7fae42cd5700  1 mon.c@2(electing) e3 handle_auth_request failed to assign global_id
    debug 2020-02-06 07:46:57.785 7fae414d2700  1 mon.c@2(electing).elector(563) init, last seen epoch 563, mid-election, bumping
    debug 2020-02-06 07:46:57.809 7fae414d2700 -1 mon.c@2(electing) e3 failed to get devid for : udev_device_new_from_subsystem_sysname failed on ''
    debug 2020-02-06 07:46:57.829 7fae3eccd700 -1 mon.c@2(electing) e3 failed to get devid for : udev_device_new_from_subsystem_sysname failed on ''
    debug 2020-02-06 07:46:59.425 7fae414d2700 -1 mon.c@2(electing) e3 get_health_metrics reporting 1 slow ops, oldest is log(1 entries from seq 1 at 2020-02-06 07:43:56.297914)
    ```

#### Scenario 4: Shut down a node for good, without draining (hard VM host crash)

Scenario/Execution:

- Have containers using the Ceph cluster (via RBD and CephFS volumes) constantly write and check data
- All pools without redundancy
- Pick a node with just an OSD and a Mon and power it off using openstack

Effect:

- Writers stall
- Rook reschedules CephFS and Mon daemons
- Mon cannot be rescheduled due to lack of nodes
- State after ~4m:

    ```
    cluster:
        id:     da1f93e9-8ce0-47ee-82c7-f32a5d0caedf
        health: HEALTH_WARN
                2 MDSs report slow metadata IOs
                1 MDSs report slow requests
                1 osds down
                1 host (1 osds) down
                Reduced data availability: 7 pgs inactive
                2 daemons have recently crashed
                1/3 mons down, quorum a,b

    services:
        mon: 3 daemons, quorum a,b (age 3m), out of quorum: c
        mgr: a(active, since 3m)
        mds: ceph-fs:1 {0=ceph-fs-a=up:active} 1 up:standby-replay
        osd: 3 osds: 2 up (since 4m), 3 in (since 19h)

    data:
        pools:   3 pools, 24 pgs
        objects: 1.23k objects, 1.9 GiB
        usage:   3.9 GiB used, 174 GiB / 178 GiB avail
        pgs:     29.167% pgs unknown
                 17 active+clean
                 7  unknown
    ```

- Wat, it killed the operator?!

    ```
    po/rook-ceph-operator-7d65b545f7-8x4z8                              1/1       Running       0          10s
    po/rook-ceph-operator-7d65b545f7-wj9jb                              1/1       Terminating   1          32m
    ```

    Oh... it was running on the node I killed...

- At 10m, the OSD is still not respawned. The issue is:

    ```
    FirstSeen     LastSeen        Count   From                            SubObjectPath   Type            Reason                  Message
    ---------     --------        -----   ----                            -------------   --------        ------                  -------
    9m            9m              1       default-scheduler                               Normal          Scheduled               Successfully assigned rook-ceph/rook-ceph-osd-2-86d456488b-628rc to managed-k8s-worker-2
    9m            9m              1       attachdetach-controller                         Warning         FailedAttachVolume      Multi-Attach error for volume "pvc-f3af19ea-0c59-44fa-a574-e1e9a86b6199" Volume is already used by pod(s) rook-ceph-osd-2-86d456488b-m45kb
    7m            59s             4       kubelet, managed-k8s-worker-2                   Warning         FailedMount             Unable to mount volumes for pod "rook-ceph-osd-2-86d456488b-628rc_rook-ceph(5a0ce905-028c-4dca-b610-7e116968e8ab)": timeout expired waiting for volumes to attach or mount for pod "rook-ceph"/"rook-ceph-osd-2-86d456488b-628rc". list of unmounted volumes=[cinder-2-ceph-data-qt5dp]. list of unattached volumes=[rook-data rook-config-override rook-ceph-log rook-ceph-crash devices cinder-2-ceph-data-qt5dp cinder-2-ceph-data-qt5dp-bridge run-udev rook-binaries rook-ceph-osd-token-4tlzx]
    ```

- I’m now hard-detaching the volume from the powered off instance...
- Did not help. After >1h, the cluster is still broken. Since we do not have any
  redundancy, we cannot recover from this unless we reboot the node, which is
  unfortunate; the volume exists and the data is there, but cinder CSI can’t
  re-attach it :(
- Now I deleted the wrong node and probably broke the cluster :(
- Re-starting worker-1 in the attempt to recover
- Mons and OSDs are being rescheduled
- It’s ceph we’re talking about. The cluster is healthy, despite me messing
  in more ways with it (unintentionally!):

  - Hard-reboot another node
  - systemctl restart docker on *all* nodes (masters and workers)


#### Scenario 4a: Hard-poweroff a node without draining, delete the node

Scenario/Execution:

- Have containers using the Ceph cluster (via RBD and CephFS volumes) constantly write and check data
- All pools without redundancy
- Pick a node with just an OSD and a Mon and power it off using openstack
- Once containers enter Terminating state, delete the node

Effect:

- Writers are blocked as soon as node is off
-
    ```
    cluster:
        id:     da1f93e9-8ce0-47ee-82c7-f32a5d0caedf
        health: HEALTH_WARN
                2 MDSs report slow metadata IOs
                1 MDSs report slow requests
                1 osds down
                1 host (1 osds) down
                Reduced data availability: 7 pgs stale
                4 daemons have recently crashed
                1/3 mons down, quorum a,c

    services:
        mon: 3 daemons, quorum a,c (age 2m), out of quorum: b
        mgr: a(active, since 16m)
        mds: ceph-fs:1 {0=ceph-fs-b=up:active} 1 up:standby-replay
        osd: 3 osds: 2 up (since 2m), 3 in (since 59m)

    data:
        pools:   3 pools, 24 pgs
        objects: 2.10k objects, 2.5 GiB
        usage:   5.5 GiB used, 261 GiB / 267 GiB avail
        pgs:     17 active+clean
                 7  stale+active+clean
    ```

- Terminating pods disappear and OSD gets rescheduled. blocked on Volume
  (but wait for it ...)

  ```
  Events:
    FirstSeen     LastSeen        Count   From                            SubObjectPath   Type            Reason                  Message
    ---------     --------        -----   ----                            -------------   --------        ------                  -------
    2m            2m              1       default-scheduler                               Normal          Scheduled               Successfully assigned rook-ce
    ph/rook-ceph-osd-2-86d456488b-slmf6 to managed-k8s-worker-2
    2m            2m              1       attachdetach-controller                         Warning         FailedAttachVolume      Multi-Attach error for volume
    "pvc-f3af19ea-0c59-44fa-a574-e1e9a86b6199" Volume is already used by pod(s) rook-ceph-osd-2-86d456488b-dg775
    10s           10s             1       kubelet, managed-k8s-worker-2                   Warning         FailedMount             Unable to mount volumes for p
    od "rook-ceph-osd-2-86d456488b-slmf6_rook-ceph(8405cbb6-95ff-4512-befa-e279009e2e07)": timeout expired waiting for volumes to attach or mount for pod "rook-ceph"/"rook-ceph-osd-2-86d456488b-slmf6". list of unmounted volumes=[cinder-2-ceph-data-qt5dp]. list of unattached volumes=[rook-data rook-config-override rook-ceph-log rook-ceph-crash devices cinder-2-ceph-data-qt5dp cinder-2-ceph-data-qt5dp-bridge run-udev rook-binaries rook-ceph-osd-token-4tlzx]
  ```

  (it can take up to 5 minutes for cinder to recognize that a pod is gone and re-try attaching a volume...)

- Mon does not get rescheduled for the usual reasons (anti-affinity)
- Aaand there we go. After ~10 minutes of downtime, the OSD is up again and
  data is available.
