# Architecture

This project uses Ansible and OpenStack to provide a customizable, highly available and flexible managed K8s installation.
![Platform architecture](img/Architecture.svg)

The setup routine creates the folder structure **/home/ubuntu/.managed_k8s** on the node **master1**. It contains k8s resources used to connect to the underlying OS infrastructure and to do some smoketesting.

**Note: The following text consists of rough notes on the architecture**

* three kinds of hosts: gateway nodes, k8s master nodes and k8s worker nodes
* gateway nodes are made redundant via keepalived
* the number of master nodes should be uneven (1, 3, 5, ..) because K8s uses the Raft protocol. In order to prevent the split brain problem the majority of nodes has to be up with 3 master nodes, one can fail without problem. With 2 out, the last one will stop working because it does not know if this is just a network partitioning. 5 nodes can handle 2 failed nodes

Multi-Master K8s setup with etcd database running on the same VMs.

Gateway nodes are the only entrypoints into the private network because they are the only ones holding floating IPs. They also act as SSH jumphosts. Each gateway hosts an instance of HAProxy. HAProxy acts a load-balancing endpoint for the K8s apiserver. The gateways are made redundant with keepalived. An extra network port is used to hold both the private and the public virtual IP (VIP). As a health check, a script queries the /healthz resource of HAProxy. Both services run in docker containers for isolation. They might in the future, however, be jailed by systemd instead.

On each master node, an OpenStack cloud controller manager (CCM) is running that acts as an interface between the cluster and OpenStack. Kubelet is started with --cloud-provider=external. Block storage can be dynamically provisioned by OS cinder via the Cinder Container Storage Interface (CSI) plugin.

Backups should be made of all credentials (certificates), the etcd database and, if necessary, persistent volumes. Backups are useful when, e.g., a K8s upgrade fails or the user accidently deleted an important resource. A cronjob dumps the etcd database every N minutes and ensures that the number of backup instances is contained. One candidate for managing the backups is borg. To restore the cluster re-run kubeadm with an existing etcd database.


# Quickstart

This guide will give you a brief introduction on how to set up the environment.

## Requirements

* Install the OpenStack python client and Ansible, preferably in a virtual environment.
* Make sure you have access to your OpenStack project.
* If not done yet, create an SSH keypair and add it to your OpenStack project.

## Deployment

The deployment happens in multiple stages.

- Step 1 spawns all infrastructure on IaaS level. `ansible-playbook -i inventories/<customer>/01_openstack/provision.yaml`
- Step 2 sets up the gateway nodes and prepares wireguard. `ansible-playbook -i inventories/<customer>/02_trampoline/openstack.yaml 02_gateways.yaml`
- Step 3 sets up the cluster itself. `ansible-playbook -i inventories/<customer>/03_final/openstack.yaml 03_site.yaml`
- Step 4 tests the basic functionality of the cluster. It uses the same inventory as in step 3. `ansible-playbook -i inventories/<customer>/03_final/openstack.yaml 04_tests.yaml`

Important: the deployment is not fully automated yet. Information will be added.

* IP of the Virtual-IP (VIP) port
* name of the worker nodes used in the test
* wireguard configuration has to be set up manually
* wireguard overlay network ip range
* ...

## Upgrading

Use the playbook 05_upgrade_cluster.yaml that implements the steps mentioned in https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/. Be sure to know what you're doing.

## Resetting a cluster

Use the playbook teardown_cluster.yaml that runs `kubeadm reset` and removes the packages for kubeadm, kubectl and kubelet on all k8s nodes.

# How to create a new project for a customer

* apply for extra resources @operations (**TODO:** determine how much resources are needed)
* let them create a dedicated user account for the client
* if it's a demo site, do not set the reset email to something owned by the client but leave it internal
* Note: OpenStack does not support user password reset natively. C&H developed its own solution which has a crude user management. It assumes that a user name is always a valid mail address (which hence is unique). OS, however, allows arbitrary user names. From what I understood the reset applet queries the user database and selects the first user that matches. Consequently, you can a) just give an email address to the reset dialogue and b) cannot request a password reset for an account whose name is not an email address.
* make sure that nothing in the project that is visible to the user is linked to another customer.

* copy the inventory 
* add the operator's keypair to the new OpenStack project


* the user receives: the cloud.yaml OpenStack configuration for the project and an SSH keypair. **TODO:** What about a wireguard keypair?

## Interfacing the user

* prepare, test and hand over:
    0. sshconfig
    1. SSH keypair
    2. OpenStack clouds.yaml 
    3. wireguard keypair
    4. kubeconfig

### Auto-generated ssh-config

1. Write the output of `openstack server list -f json` into a file <servers>
2. Use utils/ssh_conf.py to auto-generate an ssh configuration file for the the cluster
3. Use it like `ssh -F <ssh_config> master-az1`. The configuration uses the private IPs of the servers. Wireguard must therefore be running. 
4. Move <ssh_config> to the `.etc/` subdir in the `03_final` folder.

### Adding SSH-keys

Use playbook helpers.yaml with the tag *public_key*. The SSH keys (`ssh_public_keys`) are placed inside group_vars/all.yaml in stage 03_final. Removing keys has to happen manually for now.
