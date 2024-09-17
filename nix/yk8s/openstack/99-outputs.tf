resource "local_file" "inventory_yaook-k8s" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    masters       = openstack_compute_instance_v2.master,
    master_ports  = openstack_networking_port_v2.master,
    gateways      = openstack_compute_instance_v2.gateway,
    gateway_ports = openstack_networking_port_v2.gateway,
    gateway_fips  = openstack_networking_floatingip_v2.gateway,
    workers       = openstack_compute_instance_v2.worker,
    worker_ports  = openstack_networking_port_v2.worker,
    ipv6_enabled = var.ipv6_enabled,
    ipv4_enabled = var.ipv4_enabled,
  })
  filename        = "../../state/terraform/rendered/hosts"
  file_permission = 0640
}

resource "local_file" "trampoline_gateways" {
  content         = data.template_file.trampoline_gateways.rendered
  filename        = "../../state/terraform/rendered/terraform_networking-trampoline.yaml"
  file_permission = 0640
}

resource "local_file" "final_networking" {
  content = templatefile("${path.module}/templates/final_networking.tpl", {
    subnet_id              = try(openstack_networking_subnet_v2.cluster_subnet[0].id, null),
    subnet_v6_id           = try(openstack_networking_subnet_v2.cluster_v6_subnet[0].id, null),
    floating_ip_network_id = data.openstack_networking_network_v2.public_network.id,
  })
  filename        = "../../state/terraform/rendered/terraform_networking.yaml"
  file_permission = 0640
}
