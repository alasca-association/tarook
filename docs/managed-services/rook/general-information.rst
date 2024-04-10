Rook - General information
==========================

.. todo::

   needs updates (differentiate between on OpenStack and on Bare
   Metal)

For the usage of RWX (ReadWriteMany) volumes,
a distributed storage system is needed.
Ceph is a distributed storage system which allows
to supply normal block devices (ReadWriteOnce volumes or real disks)
in differing formats via network.
In particular, it can supply them as ReadWriteMany volumes
via CephFS.

-  We configure the cluster to use Cinder CSI volumes as backing
   storage. The volumes are already replicated on our OpenStack’s Ceph
   level, so we set the pool size to 1 (= one replica only) in the Rook
   cluster.

-  Cinder volumes are numbered in rook (e.g. ``cinder-2-ceph-data``).
   The numbering does *not always* correspond to the OSD number using
   that volume! This is important when debugging OSD issues and when
   removing OSDs and their storage especially.

-  To access ceph tools, run:

   .. code:: console

      $ kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

-  Rook stores information about the provisioning state of volumes in
   ConfigMap objects while the provisioning hasn’t completed yet. When
   removing a provisioning job half way through, it is important to also
   clean up the corresponding ConfigMap object, otherwise the operator
   will hang.

-  The ceph mons may use the ``local-storage`` StorageClass which is a fancy
   version of ``hostPath`` and has the advantage of “binding” a pod to a
   node. ``local-storage`` works through a controller that presents
   disks (or bind-mounts of directories, as in our case) as PVs to K8s.
   The controller also attaches PVCs to these PVs.

-  Note that it’s *usually* safe to delete a ceph mon and its PVC if at
   least one healthy mon remains. To be on the safe side, make sure the
   quorum is ``> floor(mons / 2).``
