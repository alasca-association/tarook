resource "local_file" "inventory_stage2" {
  content = templatefile("${path.module}/templates/inventory_stage2.tpl", {
    masters       = openstack_compute_instance_v2.master,
    master_ports  = openstack_networking_port_v2.master,
    gateways      = openstack_compute_instance_v2.gateway,
    gateway_ports = openstack_networking_port_v2.gateway,
    gateway_fips  = openstack_networking_floatingip_v2.gateway,
    workers       = openstack_compute_instance_v2.worker,
    worker_ports  = openstack_networking_port_v2.worker,
  })
  filename        = "${path.cwd}/../inventory/02_trampoline/hosts"
  file_permission = 0640
}

resource "local_file" "inventory_stage3" {
  content = templatefile("${path.module}/templates/inventory_stage3.tpl", {
    masters       = openstack_compute_instance_v2.master,
    master_ports  = openstack_networking_port_v2.master,
    gateways      = openstack_compute_instance_v2.gateway,
    gateway_ports = openstack_networking_port_v2.gateway,
    workers       = openstack_compute_instance_v2.worker,
    worker_ports  = openstack_networking_port_v2.worker,
  })
  filename        = "${path.cwd}/../inventory/03_final/hosts"
  file_permission = 0640
}

terraform {
  backend "local" {
    path = "../../terraform/terraform.tfstate"
  }
}
