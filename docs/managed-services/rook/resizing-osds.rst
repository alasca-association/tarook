Resizing an OSD
===============

Prerequisites
-------------

-  You need a shell inside the Ceph toolbox. You can open such a shell
   with:

   .. code:: console

      $ kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

-  The ceph cluster must be healthy.

Change the size of a single OSD
-------------------------------

In theory, there are two ways to go about this. In general, the plan is
to increase the OSD size in the cluster configuration and then
substitute an existing OSD. This can be done by either first removing
the existing OSD or by first adding a new OSD.

It is important to remember the restrictions around removal of OSDs:
only the OSD on the highest numbered volume can be permanently removed
from the cluster; any other OSD would be recreated by the operator,
despite a reduced OSD count.

This makes it impossible to first add a larger OSD and then
(permanently) remove a smaller OSD: the newly added larger OSD would
have the highest numbered volume, and would thus be the only OSD you can
permanently remove from the cluster.

Thus, the only feasible way is to first remove any OSD and have the
operator replace it with a larger one. Note that this replacement is
exactly the effect which prevents us from permanently removing any OSD
except the one on the highest numbered volume.

If you do not have enough space in the cluster to buffer away the data
of an OSD, you can temporarily increase the OSD count by one and later
remove that newly created OSD.

Note that all of this applies in the same way to resizing an OSD to a
smaller volume size and to resizing many OSDs (though you probably
shouldn’t resize many at once, for your own cognitive good).

The steps are in many places very similar to removing an OSD, but since
we don’t want to change the overall amount of OSDs, we’ll never decrease
the OSD count.

.. caution::
   
   This process will create and attach Cinder Volumes. Due to a
   known kernel bug, this may crash the Ceph workers. Ceph will recover
   from this, however, it may lead to temporarily unavailable data.

1. Ensure that the cluster is healthy and pick a victim OSD to remove:

   .. code:: console

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

   Pick one of the OSDs. In this example, we’ll “resize” the OSD with
   ID 2.

   We need to find the volume which the OSD uses, which we do with:

   .. code:: console

      $ kubectl -n rook-ceph describe pod -l ceph-osd-id=2
      […]
      cinder-1-ceph-data-8hd8s:
         Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
         ClaimName:  cinder-1-ceph-data-8hd8s
         ReadOnly:   false
      […]

   ``$id`` shall now refer to ``2``, ``$name`` shall refer to
   ``osd.2``, ``$volume`` shall refer to ``cinder-1-ceph-data-8hd8s``.

   (This is also an excellent example of OSD IDs not mapping 1:1 to
   volume indices.)

2. Set the new target volume size. Update the ``config.toml`` of
   kubernetes cluster by setting
   ``k8s-service-layer.rook.osd_volume_size`` to the new desired size.

   Run the ``toml_helper.py`` and apply the changes by running ansible
   stage 3 (possibly with ``-t rook`` to only apply the rook changes).

3. Evict all data from the victim OSD.

   .. code:: console

      toolbox# ceph osd crush reweight $name 0

4. Wait for the migration to finish.

   You can run ``watch ceph osd df`` as well as ``watch ceph -s`` to
   observe the migration status; the former will show how the number of
   placement groups (``PGS`` column) for that OSD decreases, while the
   latter will show the status of the cluster overall.

   The migration is over when:

   -  The number of placement groups for your victim OSD is 0
   -  All placement groups show as active+clean in ``ceph -s``

   .. note::
      
      The ``RAW USE`` column of the ``ceph osd df`` output does not
      decrease for some reason. The column to look at is ``DATA``, which
      should reduce to something in the order of ``10 MiB``.

   .. code:: console

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

6. Restart the operator to trigger the removal of the evicted OSD:

   .. code:: console

      $ kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas 0
      $ sleep 5
      $ kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas 1

7. Wait until the operator has deleted the OSD pod (should be at most
   10 minutes).

   .. code:: console

      $ watch kubectl -n rook-ceph get pod -l ceph-osd-id=$id

   This command should print “No resources found in rook-ceph
   namespace.”.

   (Rook will auto-delete OSDs which are marked as out and have no
   placement groups.)

8. Purge the OSD. *If the data has not been moved, data loss will occur
   here!*

   .. code:: console

      toolbox# ceph osd purge $name

   .. note::
      
      You do not need ``--yes-i-really-mean-it`` since all data
      was moved to another device. If ceph asks you for
      ``--yes-i-really-mean-it`` something is wrong!

   ``ceph osd df`` should not list the OSD anymore, and ``ceph -s``
   should say that there are now only 2 OSDs (if you started out with
   3), all of which should be up and in.

9. Delete the preparation job and the PVC.

   .. caution::
      
      Deleting the wrong job + pvc will inevitably lead to
      loss of data! Double-check that you’re killing the correct volume by
      first running:

   .. code:: console

      $ kubectl -n rook-ceph describe pvc $volume

   The ``MountedBy:`` line should only list a single user, which is
   ``rook-ceph-osd-prepare-$volume-$suffix`` (where ``$suffix`` is a
   random thing).

   Once you’ve verified that, you can delete the job and the PVC:

   .. code:: console

      $ kubectl -n rook-ceph delete job rook-ceph-osd-prepare-$volume
      $ kubectl -n rook-ceph delete pvc $volume

   Verify that the volume is gone with ``kubectl get pvc -n rook-ceph``
   and in openstack.

10.   Restart the operator to trigger re-creation of the OSD.

      .. code:: console

         $ kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas 0
         $ sleep 5
         $ kubectl -n rook-ceph scale deployment rook-ceph-operator --replicas 1

      You can observe progress by watching the pod list and
      ``ceph osd df``. The newly created volume
      (``kubectl -n rook-ceph get pvc``) should have the new size.

      The process is done when you see:

      -  all OSDs in ``ceph -s`` as up and in, and
      -  all placement groups as ``active+clean``

      .. code:: console

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
