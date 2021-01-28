* Define IPPools
  * in template file ippools.yaml
* calico version (for calicoctl)
* asnumber: AS number used by the cluster (refer https://en.wikipedia.org/wiki/Autonomous_system_%28Internet%29#ASN_Table)
* Cluster ID:

* deploy calico on gateways
  * https://docs.projectcalico.org/getting-started/bare-metal/installation/binary-mgr
  * https://docs.projectcalico.org/getting-started/bare-metal/installation/container
  * https://docs.projectcalico.org/networking/advertise-service-ips
  * https://docs.projectcalico.org/networking/advertise-service-ips

* Calicoctl will always change nodes
  * When applying a resource:
  -  if the resource does not already exist (as determined by it's primary
     identifiers) then it is created
  -  if the resource already exists then the specification for that resource is
     replaced in it's entirety by the new resource specification.

## [Upgrade Calico Resources](https://docs.projectcalico.org/maintenance/kubernetes-upgrade#upgrading-an-installation-that-uses-the-kubernetes-api-datastore)
