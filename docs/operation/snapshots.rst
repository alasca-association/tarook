Using snapshots
===============

The yaook/k8s cluster provides the functionality of creating snapshots of your PVCs in Openstack.

Creating snapshot
-----------------

The yk8s LCM provides besides the default storage-class ``csi-sc-cinderplugin``
a default volume-snapshot-class ``csi-cinder-snapclass``.
To create a snapshot for a PVC apply the following yaml (make changes accordingly).
You can create your own VolumeSnapshotClass, see
``managed-k8s/k8s-base/roles/connect-k8s-to-openstack/files/cinder/volume_snapshot_storag_class.yaml`` for details.

.. code:: yaml

   apiVersion: snapshot.storage.k8s.io/v1
   kind: VolumeSnapshot
   metadata:
     name: <name-of-snapshot>
     namespace: <namespace>
   spec:
     volumeSnapshotClassName: csi-cinder-snapclass
     source:
       persistentVolumeClaimName: <name-of-PVC>

Rehydrating snapshot
--------------------

To rehydrate a previous snapshot apply the following yaml (make changes accordingly)

.. code:: yaml

   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
   name: <name-of-restore-pvc>
   namespace: <namespace>
   spec:
   storageClassName: csi-sc-cinderplugin
   dataSource:
     name: <name-of-snapshot>
     kind: VolumeSnapshot
     apiGroup: snapshot.storage.k8s.io
   accessModes:
     - ReadWriteOnce
   resources:
     requests:
       storage: 2Gi

Deleting snapshot
-----------------

When deleting snapshots make sure to first remove any rehydration of it.
To remove a PV, snapshots created from it also need to be removed before.
k8s doesn't exit with an error or warning if a deletion wasn't successful.
Also ``kubectl get volumesnapshots -A`` may output no snapshots, but ``openstack volume snapshot list`` will.
