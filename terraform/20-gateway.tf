resource "openstack_compute_secgroup_v2" "gateway_secgroup" {
  name        = var.gateway_security_group_name
  description = "Security group for HAProxy ports"

  dynamic "rule" {
    for_each = var.haproxy_ports

    content {
      ip_protocol = "tcp"
      cidr        = "0.0.0.0/0"
      from_port   = rule.value
      to_port     = rule.value
    }
  }
}

resource "openstack_networking_port_v2" "gw_vip_port" {
  name           = var.vip_port_name
  admin_state_up = true
  network_id     = openstack_networking_network_v2.cluster_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }

  security_group_ids = [
    data.openstack_networking_secgroup_v2.default.id,
    openstack_compute_secgroup_v2.gateway_secgroup.id,
    openstack_compute_secgroup_v2.vpn.id
  ]
}

resource "openstack_networking_floatingip_v2" "gw_vip_fip" {
  pool        = var.public_network
  description = "Floating IP associated with the VRRP port"
  port_id     = openstack_networking_port_v2.gw_vip_port.id

  depends_on = [
    openstack_networking_router_interface_v2.cluster_router_iface
  ]
}


resource "openstack_networking_port_v2" "gateway" {
  count = length(var.azs)
  name  = "managed-k8s-gw-${lower(var.azs[count.index])}"

  network_id = openstack_networking_network_v2.cluster_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }

  port_security_enabled = false
}

resource "openstack_blockstorage_volume_v2" "gateway-volume" {
  count = var.boot_from_volume == true ? length(var.azs) : null
  name     = "managed-k8s-gw-volume-${try(var.azs[count.index], count.index)}"
  size     = data.openstack_compute_flavor_v2.gateway.disk
  image_id = data.openstack_images_image_v2.gateway.id

  timeouts {
    create = var.timeout_time
    delete = var.timeout_time
  }
}

resource "openstack_compute_instance_v2" "gateway" {
  count = var.boot_from_volume == false ? length(openstack_networking_port_v2.gateway) : null

  name              = openstack_networking_port_v2.gateway[count.index].name
  image_id          = data.openstack_images_image_v2.gateway.id
  flavor_id         = data.openstack_compute_flavor_v2.gateway.id
  key_pair          = var.keypair
  availability_zone = var.enable_az_management ? var.azs[count.index] : null
  config_drive      = true

  network {
    port = openstack_networking_port_v2.gateway[count.index].id
  }
  lifecycle {
    ignore_changes = [key_pair, image_id]
  }
}

resource "openstack_compute_instance_v2" "boot-gateway" {
  count = var.boot_from_volume == true ? length(openstack_networking_port_v2.gateway) : null

  name              = openstack_networking_port_v2.gateway[count.index].name
  flavor_id         = data.openstack_compute_flavor_v2.gateway.id
  key_pair          = var.keypair
  availability_zone = var.enable_az_management ? var.azs[count.index] : null
  config_drive      = true

  block_device {
    uuid                  = openstack_blockstorage_volume_v2.gateway-volume[count.index].id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.gateway[count.index].id
  }
  lifecycle {
    ignore_changes = [key_pair, image_id]
  }
}

resource "openstack_networking_floatingip_v2" "gateway" {
  count       = length(var.azs)
  description = "Floating IP for gateway in ${var.azs[count.index]}"
  pool        = var.public_network
}

resource "openstack_compute_floatingip_associate_v2" "gateway" {
  count = length(openstack_compute_instance_v2.gateway)

  floating_ip = openstack_networking_floatingip_v2.gateway[count.index].address
  instance_id = openstack_compute_instance_v2.gateway[count.index].id

  depends_on = [
    openstack_networking_router_interface_v2.cluster_router_iface
  ]
}

data "template_file" "trampoline_gateways" {
  template = file("${path.module}/templates/trampoline_gateways.tpl")
  vars = {
    networking_fixed_ip    = "${openstack_networking_port_v2.gw_vip_port.all_fixed_ips[0]}"
    networking_floating_ip = "${openstack_networking_floatingip_v2.gw_vip_fip.address}"
    subnet_cidr            = "${openstack_networking_subnet_v2.cluster_subnet.cidr}"
  }
}

resource "local_file" "trampoline_gateways" {
  content         = data.template_file.trampoline_gateways.rendered
  filename        = "./../inventory/02_trampoline/group_vars/gateways/rendered.yaml"
  file_permission = 0640
}

resource "local_file" "final_group_all" {
  content         = data.template_file.trampoline_gateways.rendered
  filename        = "./../inventory/03_final/group_vars/all/rendered_ip.yaml"
  file_permission = 0640
}
