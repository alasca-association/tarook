# Spawning a Cluster

<!-- TODO: needs updating with current LCM -->

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
