## Bootstrap a cluster

1. Install terraform
2. Load your openstack credentials into the shell
3. ``terraform init``
4. ``terraform apply -var keypair=your-openstack-keypair -var subnet_cidr=172.30.154.0/24"

(You can pick a different subnet, but this’ll do.)

## Configure nodes

To execute an ansible stage, make sure you use the terraform inventories. To
run stage 2, you would, *for example*, call
``ansible-playbook -i inventories/terraform/02_trampoline/openstack.yaml 02_trampoline.yaml``.

1. Set up wireguard (see /docs/admin/wg.md), including running Ansible stage 02
2. ``ansible-playbook -i inventories/terraform/03_final/openstack.yaml 03_final.yaml --diff -f10``
