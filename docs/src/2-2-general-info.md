# General Information

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
