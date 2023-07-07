Initial Test Notes for Rook Ceph
================================

Issues
------

-  PVCs do not seem to get deleted when the cluster is deleted

Resilience testing
------------------

Executive Summary:

-  I was not able to put the cluster in a state which caused permanent
   data loss
-  All scenarios end, after a while, with Ceph being fully operational

Scenario 1: systemctl reboot on a node with 1 OSD and 1 Mon
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Scenario/Execution:**

-  Have containers using the Ceph cluster (via RBD and CephFS volumes)
   constantly write and check data
-  All pools without redundancy
-  Pick a node with just an OSD and a Mon and reboot it

**Effect:**

-  Writers stall while the cluster is reconfiguring
-  OSD is migrated away from the rebooted node as soon as it comes up
-  Mon is restarted sooner(?)

Scenario 2: ``kubectl drain –ignore-daemonsets –delete-local-data`` on a node with ALL the OSDs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Part 1
^^^^^^

**Scenario/Execution:**

-  Have containers using the Ceph cluster (via RBD and CephFS volumes)
   constantly write and check data
-  All pools without redundancy
-  OSDs are (for some reason) all scheduled to the same node
-  ``kubectl drain`` that node

**Effect:**

-  Writers stall while the cluster is reconfiguring
-  OSDs are rescheduled to other nodes immediately-ish
-  Mon is not rescheduled (since we only have three nodes and they’re
   configured with anti-affinity)
-  Writers resume as soon as OSDs are up
-  Cluster ends in ``HEALTH_WARN`` due to missing Mon

Part 2
^^^^^^

**Execution:**

-  ``kubectl uncordon`` the drained node

**Effect:**

-  No effect on the writers
-  Mon is rescheduled to the fresh node
-  Cluster is in ``HEALTH_WARN`` due to “2 daemons have recently crashed”.
   I’m not being gentle to this thing :>

Scenario 3: Hard-reset a node with 1 OSD and 1 Mon
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Scenario/Execution:**

-  Have containers using the Ceph cluster (via RBD and CephFS volumes)
   constantly write and check data
-  All pools without redundancy
-  Pick a node with just an OSD and a Mon and hard-reset it using
   OpenStack

**Effect:**

-  Writers stall while OSD is unavailable

   .. code:: shell

      health: HEALTH_WARN
      insufficient standby MDS daemons available
      1 MDSs report slow metadata IOs
      1 osds down
      1 host (1 osds) down
      no active mgr
      2 daemons have recently crashed
      1/3 mons down, quorum a,b

   moohahaha

-  OSD is *not* rescheduled to another node. Probably too quick for rook
   to act?
-  No data loss AFAICT
-  mon failed to re-join quorum for minutes
-  deleted the pod, which did not seem to help
-  however, it joined quorum after four more minutes. loop of:

   .. code:: shell

      debug 2020-02-06 07:46:56.889 7fae42cd5700  1 mon.c@2(electing) e3 handle_auth_request failed to assign global_id
      debug 2020-02-06 07:46:57.785 7fae414d2700  1 mon.c@2(electing).elector(563) init, last seen epoch 563, mid-election, bumping
      debug 2020-02-06 07:46:57.809 7fae414d2700 -1 mon.c@2(electing) e3 failed to get devid for : udev_device_new_from_subsystem_sysname failed on ''
      debug 2020-02-06 07:46:57.829 7fae3eccd700 -1 mon.c@2(electing) e3 failed to get devid for : udev_device_new_from_subsystem_sysname failed on ''
      debug 2020-02-06 07:46:59.425 7fae414d2700 -1 mon.c@2(electing) e3 get_health_metrics reporting 1 slow ops, oldest is log(1 entries from seq 1 at 2020-02-06 07:43:56.297914)

Scenario 4: Shut down a node for good, without draining (hard VM host crash)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Scenario/Execution:**

-  Have containers using the Ceph cluster (via RBD and CephFS volumes)
   constantly write and check data
-  All pools without redundancy
-  Pick a node with just an OSD and a Mon and power it off using
   openstack

**Effect:**

-  Writers stall
-  Rook reschedules CephFS and Mon daemons
-  Mon cannot be rescheduled due to lack of nodes
-  State after ~4m:

   .. code:: shell

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

   Wat, it killed the operator?!

   .. code:: shell

      po/rook-ceph-operator-7d65b545f7-8x4z8                              1/1       Running       0          10s
      po/rook-ceph-operator-7d65b545f7-wj9jb                              1/1       Terminating   1          32m

   Oh… it was running on the node I killed…

-  At 10m, the OSD is still not respawned. The issue is:

   .. code:: shell

      FirstSeen     LastSeen        Count   From                            SubObjectPath   Type            Reason                  Message
      ---------     --------        -----   ----                            -------------   --------        ------                  -------
      9m            9m              1       default-scheduler                               Normal          Scheduled               Successfully assigned rook-ceph/rook-ceph-osd-2-86d456488b-628rc to managed-k8s-worker-2
      9m            9m              1       attachdetach-controller                         Warning         FailedAttachVolume      Multi-Attach error for volume "pvc-f3af19ea-0c59-44fa-a574-e1e9a86b6199" Volume is already used by pod(s) rook-ceph-osd-2-86d456488b-m45kb
      7m            59s             4       kubelet, managed-k8s-worker-2                   Warning         FailedMount             Unable to mount volumes for pod "rook-ceph-osd-2-86d456488b-628rc_rook-ceph(5a0ce905-028c-4dca-b610-7e116968e8ab)": timeout expired waiting for volumes to attach or mount for pod "rook-ceph"/"rook-ceph-osd-2-86d456488b-628rc". list of unmounted volumes=[cinder-2-ceph-data-qt5dp]. list of unattached volumes=[rook-data rook-config-override rook-ceph-log rook-ceph-crash devices cinder-2-ceph-data-qt5dp cinder-2-ceph-data-qt5dp-bridge run-udev rook-binaries rook-ceph-osd-token-4tlzx]

-  I’m now hard-detaching the volume from the powered off instance…
-  Did not help. After >1h, the cluster is still broken. Since we do not
   have any redundancy, we cannot recover from this unless we reboot the
   node, which is unfortunate; the volume exists and the data is there,
   but cinder CSI can’t re-attach it :(
-  Now I deleted the wrong node and probably broke the cluster :(
-  Re-starting worker-1 in the attempt to recover
-  Mons and OSDs are being rescheduled
-  It’s ceph we’re talking about. The cluster is healthy, despite me
   messing in more ways with it (unintentionally!):

   -  Hard-reboot another node
   -  ``systemctl restart docker`` on *all* nodes (masters and workers)

Scenario 4a: Hard-poweroff a node without draining, delete the node
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Scenario/Execution:**

-  Have containers using the Ceph cluster (via RBD and CephFS volumes)
   constantly write and check data
-  All pools without redundancy
-  Pick a node with just an OSD and a Mon and power it off using
   openstack
-  Once containers enter Terminating state, delete the node

**Effect:**

-  Writers are blocked as soon as node is off

   .. code:: shell

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

-  Terminating pods disappear and OSD gets rescheduled. blocked on
   Volume (but wait for it …)

   .. code:: shell

      Events:
        FirstSeen     LastSeen        Count   From                            SubObjectPath   Type            Reason                  Message
        ---------     --------        -----   ----                            -------------   --------        ------                  -------
        2m            2m              1       default-scheduler                               Normal          Scheduled               Successfully assigned rook-ce
        ph/rook-ceph-osd-2-86d456488b-slmf6 to managed-k8s-worker-2
        2m            2m              1       attachdetach-controller                         Warning         FailedAttachVolume      Multi-Attach error for volume
        "pvc-f3af19ea-0c59-44fa-a574-e1e9a86b6199" Volume is already used by pod(s) rook-ceph-osd-2-86d456488b-dg775
        10s           10s             1       kubelet, managed-k8s-worker-2                   Warning         FailedMount             Unable to mount volumes for p
        od "rook-ceph-osd-2-86d456488b-slmf6_rook-ceph(8405cbb6-95ff-4512-befa-e279009e2e07)": timeout expired waiting for volumes to attach or mount for pod "rook-ceph"/"rook-ceph-osd-2-86d456488b-slmf6". list of unmounted volumes=[cinder-2-ceph-data-qt5dp]. list of unattached volumes=[rook-data rook-config-override rook-ceph-log rook-ceph-crash devices cinder-2-ceph-data-qt5dp cinder-2-ceph-data-qt5dp-bridge run-udev rook-binaries rook-ceph-osd-token-4tlzx]

   (it can take up to 5 minutes for cinder to recognize that a pod is
   gone and re-try attaching a volume…)

-  Mon does not get rescheduled for the usual reasons (anti-affinity)
-  Aaand there we go. After ~10 minutes of downtime, the OSD is up again
   and data is available.
