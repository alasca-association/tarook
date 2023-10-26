resource "local_file" "inventory_yaook-k8s" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    masters       = openstack_compute_instance_v2.master,
    master_ports  = openstack_networking_port_v2.master,
    gateways      = openstack_compute_instance_v2.gateway,
    gateway_ports = openstack_networking_port_v2.gateway,
    gateway_fips  = openstack_networking_floatingip_v2.gateway,
    workers       = openstack_compute_instance_v2.worker,
    worker_ports  = openstack_networking_port_v2.worker,
    dualstack_support = var.dualstack_support,
  })
  filename        = "../../inventory/yaook-k8s/hosts"
  file_permission = 0640
}

resource "local_file" "trampoline_gateways" {
  content         = data.template_file.trampoline_gateways.rendered
  filename        = "../../inventory/yaook-k8s/group_vars/all/tofu_networking-trampoline.yaml"
  file_permission = 0640
}

resource "local_file" "final_group_all" {
  content         = data.template_file.trampoline_gateways.rendered
  filename        = "../../inventory/yaook-k8s/group_vars/all/tofu_networking-trampoline.yaml"
  file_permission = 0640
}

resource "local_file" "final_networking" {
  content = templatefile("${path.module}/templates/final_networking.tpl", {
    subnet_id              = openstack_networking_subnet_v2.cluster_subnet.id,
    subnet_v6_id           = try(openstack_networking_subnet_v2.cluster_v6_subnet[0].id, null)
    floating_ip_network_id = data.openstack_networking_network_v2.public_network.id,
    subnet_cidr            = openstack_networking_subnet_v2.cluster_subnet.cidr,
    subnet_v6_cidr         = try(openstack_networking_subnet_v2.cluster_v6_subnet[0].cidr, null)
  })
  filename        = "../../inventory/yaook-k8s/group_vars/all/tofu_networking.yaml"
  file_permission = 0640
}

# Please note that if gitlab_backend is set to true in config.toml
# it will override this local backend configuration
terraform {
  backend "local" {
    path = "../../tofu/terraform.tfstate"
  }
}
