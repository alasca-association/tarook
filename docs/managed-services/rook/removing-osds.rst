Reducing the number of OSDs
===========================

If the load on the meta machines is too high because of the number of
OSDs, the number of OSDs can be reduced losslessly. This requires a few
steps and great care, but it is possible.

Prerequisites
-------------

-  You need a shell inside the Ceph toolbox. You can open such a shell
   with:

   .. code:: console

      $ kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

-  The ceph cluster must be healthy (refer to
   `Cluster Health Verification <https://rook.io/docs/rook/v1.2/ceph-upgrade.html#health-verification>`__).

Remove an OSD without data loss
-------------------------------

The following procedure was tested and verified in a test cluster with 6
OSDs. To check that no data loss occurs, a volume was created with 8 GiB
of data on it. 4 GiB were zeroes and 4 GiB were random numbers. The data
was validated after each step against SHA256 checksums without any
caches.

During creation of the data, it was ensured by watching the output of
``ceph osd df`` that all OSDs got a share of the data to prevent a false
negative. In addition, the procedure was repeated three times.

1. Check the current disk usage of the OSDs:

   .. code:: console

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

   In this example, we have six OSDs. Most of them have around 2.2 GiB
   of data on them. One has only 1.0 GiB of data (osd.0) and one has
   5.6 GiB of data (osd.3).

2. Find the OSD to remove. You can only remove the OSD with the
   highest-numbered cinder volume PVC.

   .. note::
      
      The numbering of the PVCs and OSDs is **not** equal. That
      means that OSD 0 may use volume 3 and OSD 3 may use volume 2 and OSD
      2 may use volume 0. You *always* have to discover the used volume
      using the following procedure.

   First list all the OSD PVCs:

   .. code:: console

      $ kubectl -n rook-ceph get pvc -l ceph.rook.io/DeviceSet=cinder
      NAME                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
      cinder-0-ceph-data-v6grl   Bound    pvc-27cccd47-5443-462b-b8d9-fe3192945223   90Gi       RWO            csi-sc-cinderplugin   134m
      cinder-1-ceph-data-8hd8s   Bound    pvc-83c714af-617b-4834-b9be-30f9b9f4e96f   90Gi       RWO            csi-sc-cinderplugin   134m
      cinder-2-ceph-data-n6gdx   Bound    pvc-9c304b41-bb0c-4a84-8481-3990f5f34618   90Gi       RWO            csi-sc-cinderplugin   134m
      cinder-3-ceph-data-446b4   Bound    pvc-3929dde6-eb35-402f-a4ff-07c00db59447   90Gi       RWO            csi-sc-cinderplugin   134m
      cinder-4-ceph-data-hjwmt   Bound    pvc-3f4f4a66-692f-4cd6-8f12-e55244da62df   90Gi       RWO            csi-sc-cinderplugin   134m
      cinder-5-ceph-data-bwctn   Bound    pvc-07400ac2-bc0c-4f97-999f-d50ba81b33ec   90Gi       RWO            csi-sc-cinderplugin   134m

   Then pick the one with the highest number in the name, in this
   example this is ``cinder-5-ceph-data-bwctn``

   .. code:: console

      $ kubectl -n rook-ceph describe pvc cinder-5-ceph-data-bwctn
      […]
      Mounted By:    rook-ceph-osd-5-c6d577548-vpscr
                     rook-ceph-osd-prepare-cinder-5-ceph-data-bwctn-89sm8
      […]

   This gives you the OSD ID of the OSD using this volume. In this
   example, the OSD ID is the same as the volume index, but you *can
   not rely on this*!

   In the following, we’ll refer to ``osd.5`` by ``$name``, to ``5`` by
   ``$id`` (ceph lingo) and to ``cinder-5-ceph-data-bwctn`` by
   ``$volume``.

   Before proceeding, check that there is enough space. For that, at
   least the amount of ``DATA`` of the OSD to remove needs to be
   ``AVAIL`` on the other OSDs combined. Due to the way ceph balances
   data, it is better if most OSDs can take most of the data of the OSD
   you remove.

   I’m not sure what’s going to happen if the data cannot be
   rebalanced, but I assume that (a) it will not cause data loss if you
   abort before removing the OSD and (b) ceph will tell you.

3. Set the weight of the OSD to 0. This makes ceph redistribute the
   data on that OSD to the other OSDs:

   .. code:: console

      toolbox# ceph osd crush reweight $name 0

   .. note::
      
      There is a difference between ``ceph osd crush reweight`` and
      ``ceph osd reweight`` (see 
      `here <https://ceph.io/geen-categorie/difference-between-ceph-osd-reweight-and-ceph-osd-crush-reweight/>`__).
      ``ceph osd crush reweight`` is a permanent weighting measure, while
      ``ceph osd reweight`` is a temporary measure which gets lost on a
      in/out cycle of an OSD.

4. Wait for the migration to finish.

   You can run ``watch ceph osd df`` as well as ``watch ceph -s`` to
   observe the migration status; the former will show how the number of
   placement groups (``PGS`` column) for that OSD decreases, while the
   latter will show the status of the cluster overall.

   The migration is over when:

   -  The number of placement groups for your victim OSD is 0
   -  All placement groups show as active+clean in ``ceph -s``

   Note: the ``RAW USE`` column of the ``ceph osd df`` output does not
   decrease for some reason. The column to look at is ``DATA``, which
   should reduce to something in the order of ``10 MiB``.

   .. code:: console

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

5. Mark the OSD as out.

   .. code:: console

      toolbox# ceph osd out $name

   ``ceph osd df`` should now show it with all zeros, and ``ceph -s``
   should still be ``HEALTH_OK`` with all placement groups being
   ``active+clean``, since the data has been moved elsewhere. **If this
   is not the case** abort now and seek help immediately!

   .. code:: console

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

6. Reduce the number of OSDs in the Cluster CRD. Update the
   ``config.toml`` of the cluster by decreasing
   ``k8s-service-layer.rook.nosds`` by one.

   Run the ``toml_helper.py`` and execute stage three (possibly with
   ``-t rook`` to only apply rook changes).

7. Wait until the cluster has updated. Watch the output of:

   .. code:: console

      $ kubectl -n rook-ceph get cephcluster rook-ceph -o yaml | tail

   until the state has changed to Updating and back to Created.

8. Wait until the operator has deleted the OSD pod.

   .. code:: console

      $ watch kubectl -n rook-ceph get pod -l ceph-osd-id=$id

   This command should print “No resources found in rook-ceph
   namespace.”.

   (Rook will auto-delete OSDs which are marked as out and have no
   placement groups.)

9. Purge the OSD. *If the data has not been moved, data loss will occur
   here!*

   .. code:: console

      toolbox# ceph osd purge $name

   .. note::
      
      You do not need ``--yes-i-really-mean-it`` since all data
      was moved to another device. If ceph asks you for
      ``--yes-i-really-mean-it`` something is wrong!

   ``ceph osd df`` should not list the OSD anymore, and ``ceph -s``
   should say that there are now only 5 OSDs (if you started out with
   6), all of which should be up and in.

   .. code:: console

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

10. Delete the preparation job and the PVC:

   .. code:: console

      $ kubectl -n rook-ceph delete job rook-ceph-osd-prepare-$volume
      $ kubectl -n rook-ceph delete pvc $volume

   Verify that the volume is gone with ``kubectl get pvc -n rook-ceph``
   and in openstack.

Congratulations, you now have one OSD less.
