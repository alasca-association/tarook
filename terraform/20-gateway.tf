resource "openstack_networking_port_v2" "gw_vip_port" {
  name = "${var.cluster_name}-gateway-vip"
  admin_state_up = true
  network_id     = openstack_networking_network_v2.cluster_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }

  dynamic "fixed_ip" {
    for_each = var.dualstack_support ? [1] : []
    content {
        subnet_id = openstack_networking_subnet_v2.cluster_v6_subnet[0].id
    }
  }

  dynamic "fixed_ip" {
    for_each = var.dualstack_support ? [1] : []
    content {
        subnet_id = openstack_networking_subnet_v2.cluster_v6_subnet[0].id
    }
  }
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
  name = "${var.cluster_name}-gw-${lower(var.azs[count.index])}"

  network_id = openstack_networking_network_v2.cluster_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }

  dynamic "fixed_ip" {
    for_each = var.dualstack_support ? [1] : []
    content {
        subnet_id = openstack_networking_subnet_v2.cluster_v6_subnet[0].id
    }
  }

  port_security_enabled = false
}

resource "openstack_blockstorage_volume_v2" "gateway-volume" {
  count = var.create_root_disk_on_volume == true ? length(var.azs) : 0
  name        = "${var.cluster_name}-gw-volume-${try(var.azs[count.index], count.index)}"
  size        = (data.openstack_compute_flavor_v2.gateway.disk > 0) ? data.openstack_compute_flavor_v2.gateway.disk : var.gateway_root_disk_volume_size
  image_id    = data.openstack_images_image_v2.gateway.id
  volume_type = var.root_disk_volume_type
  availability_zone = var.enable_az_management ? var.azs[count.index] : null

  timeouts {
    create = var.timeout_time
    delete = var.timeout_time
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_compute_instance_v2" "gateway" {
  count = length(openstack_networking_port_v2.gateway)

  name              = openstack_networking_port_v2.gateway[count.index].name
  flavor_id         = data.openstack_compute_flavor_v2.gateway.id
  image_id          = var.create_root_disk_on_volume == false ? data.openstack_images_image_v2.gateway.id : null
  key_pair          = var.keypair
  availability_zone = var.enable_az_management ? var.azs[count.index] : null
  config_drive      = true

  dynamic block_device {
    # Using "for_each" for check the conditional "create_root_disk_on_volume". It's not working as a loop. "dummy" should make this just more visible.
    for_each = var.create_root_disk_on_volume == true ? ["dummy"] : []
      content {
      uuid                  = openstack_blockstorage_volume_v2.gateway-volume[count.index].id
      source_type           = "volume"
      boot_index            = 0
      destination_type      = "volume"
      delete_on_termination = true
      }
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
    networking_fixed_ip     = openstack_networking_port_v2.gw_vip_port.all_fixed_ips[0],
    networking_fixed_ip_v6  = try(jsonencode(openstack_networking_port_v2.gw_vip_port.all_fixed_ips[1]), "null"),
    wireguard_gw_fixed_ip_v6  = try(openstack_networking_port_v2.gw_vip_port.all_fixed_ips[2], null),
    networking_floating_ip  = openstack_networking_floatingip_v2.gw_vip_fip.address,
    subnet_cidr             = openstack_networking_subnet_v2.cluster_subnet.cidr,
    subnet_v6_cidr          = try(jsonencode(openstack_networking_subnet_v2.cluster_v6_subnet[0].cidr), "null"),
    dualstack_support       = var.dualstack_support,
  }
}

resource "local_file" "trampoline_gateways" {
  content         = data.template_file.trampoline_gateways.rendered
  filename        = "../../inventory/02_trampoline/group_vars/gateways/terraform_networking-trampoline.yaml"
  file_permission = 0640
}

resource "local_file" "final_group_all" {
  content         = data.template_file.trampoline_gateways.rendered
  filename        = "../../inventory/03_k8s_base/group_vars/all/terraform_networking-trampoline.yaml"
  file_permission = 0640
}
