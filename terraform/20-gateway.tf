locals {
  gateway_nodes = {
    for idx in range(var.gateway_count) :
      "${local.nodes_prefix}${var.gateway_defaults.common_name}${idx}" => {
        image                    = var.gateway_defaults.image
        flavor                   = var.gateway_defaults.flavor
        az                       = var.spread_gateways_across_azs ? tolist(var.azs)[idx % length(var.azs)] : null
        volume_name              = "${local.nodes_prefix}${var.gateway_defaults.common_name}${idx}-volume"
        root_disk_size           = var.gateway_defaults.root_disk_size
        root_disk_volume_type    = var.gateway_defaults.root_disk_volume_type
      }
  }
}

resource "openstack_networking_port_v2" "gw_vip_port" {
  name = "${var.cluster_name}-gateway-vip"
  admin_state_up = true
  network_id     = openstack_networking_network_v2.cluster_network.id
  port_security_enabled = true

  dynamic "fixed_ip" {
    for_each = var.ipv4_enabled ? [1] : []
    content {
        subnet_id = openstack_networking_subnet_v2.cluster_subnet[0].id
    }
  }

  dynamic "fixed_ip" {
    for_each = var.ipv6_enabled ? [1] : []
    content {
        subnet_id = openstack_networking_subnet_v2.cluster_v6_subnet[0].id
    }
  }

  dynamic "fixed_ip" {
    for_each = var.ipv6_enabled ? [1] : []
    content {
        subnet_id = openstack_networking_subnet_v2.cluster_v6_subnet[0].id
    }
  }

  security_group_ids = [
    # NOTE: Openstack OVN usage requires port security to be enabled.
    #       Gateway nodes shall accept and forward any traffic hence we use
    #       the barndoor security group for them. (see #659)
    openstack_networking_secgroup_v2.barndoor.id,
  ]
}

resource "openstack_networking_floatingip_v2" "gw_vip_fip" {
  pool        = var.public_network
  description = "Floating IP associated with the VRRP port"
  port_id     = openstack_networking_port_v2.gw_vip_port.id

  depends_on = [
    openstack_networking_router_interface_v2.cluster_router_iface[0]
  ]
}


resource "openstack_networking_port_v2" "gateway" {
  for_each = local.gateway_nodes
  name = each.key

  network_id = openstack_networking_network_v2.cluster_network.id
  port_security_enabled = true

  dynamic "fixed_ip" {
    for_each = var.ipv4_enabled ? [1] : []
    content {
        subnet_id = openstack_networking_subnet_v2.cluster_subnet[0].id
    }
  }

  dynamic "fixed_ip" {
    for_each = var.ipv6_enabled ? [1] : []
    content {
        subnet_id = openstack_networking_subnet_v2.cluster_v6_subnet[0].id
    }
  }

  allowed_address_pairs {
    ip_address = openstack_networking_floatingip_v2.gw_vip_fip.fixed_ip
  }

  dynamic "allowed_address_pairs" {
    for_each = var.ipv4_enabled ? [1] : []
    content {
      ip_address = "0.0.0.0/0"
    }
  }

  dynamic "allowed_address_pairs" {
    for_each = var.ipv6_enabled ? [1] : []
    content {
      ip_address = "::/0"
    }
  }

  dynamic "allowed_address_pairs" {
    for_each = var.ipv6_enabled ? [1] : []
    content {
      ip_address = var.subnet_v6_cidr
    }
  }

  depends_on = [
    openstack_networking_floatingip_v2.gw_vip_fip
  ]

  security_group_ids = [
    openstack_networking_secgroup_v2.barndoor.id,
  ]

  lifecycle {
    ignore_changes = [
      # The allowed_address_pairs are subject to change and may get
      # (automatically) managed or extended by something else.
      # For example, the ch-k8s-lbaas controller manages them to
      # allow LBaaS traffic.
      # Terraform would reset these settings on each run if we would
      # not ignore changes
      allowed_address_pairs
    ]
  }
}

resource "openstack_blockstorage_volume_v3" "gateway-volume" {
  for_each = var.create_root_disk_on_volume == true ? local.gateway_nodes : {}
  name        = each.value.volume_name
  size        = (data.openstack_compute_flavor_v2.gateway.disk > 0) ? data.openstack_compute_flavor_v2.gateway.disk : each.value.root_disk_size
  image_id    = data.openstack_images_image_v2.gateway.id
  volume_type = each.value.root_disk_volume_type
  availability_zone = each.value.az

  timeouts {
    create = var.timeout_time
    delete = var.timeout_time
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_compute_instance_v2" "gateway" {
  for_each = local.gateway_nodes

  name              = each.key
  flavor_id         = data.openstack_compute_flavor_v2.gateway.id
  image_id          = var.create_root_disk_on_volume == false ? data.openstack_images_image_v2.gateway.id : null
  key_pair          = var.keypair
  availability_zone = each.value.az
  config_drive      = true

  dynamic block_device {
    # Using "for_each" for check the conditional "create_root_disk_on_volume". It's not working as a loop. "dummy" should make this just more visible.
    for_each = var.create_root_disk_on_volume == true ? ["dummy"] : []
      content {
      uuid                  = openstack_blockstorage_volume_v3.gateway-volume[each.key].id
      source_type           = "volume"
      boot_index            = 0
      destination_type      = "volume"
      delete_on_termination = true
      }
  }

  network {
    port = openstack_networking_port_v2.gateway[each.key].id
  }
  lifecycle {
    ignore_changes = [key_pair, image_id, config_drive]
  }
}

resource "openstack_networking_floatingip_v2" "gateway" {
  for_each    = local.gateway_nodes
  description = "Floating IP for gateway '${each.key}'${each.value.az != null ? " in ${each.value.az}" : ""}"
  pool        = var.public_network
}

resource "openstack_networking_floatingip_associate_v2" "gateway" {
  for_each = openstack_compute_instance_v2.gateway

  floating_ip = openstack_networking_floatingip_v2.gateway[each.key].address
  port_id = openstack_networking_port_v2.gateway[each.key].id

  depends_on = [
    openstack_networking_router_interface_v2.cluster_router_iface[0]
  ]
}

output gateways {
  value = openstack_compute_instance_v2.gateway
  sensitive = true
}
output gateway_ports {
  value = openstack_networking_port_v2.gateway
}
output gateway_fips {
  value = openstack_networking_floatingip_v2.gateway
}

output networking_fixed_ip {
  value = try(openstack_networking_port_v2.gw_vip_port.all_fixed_ips[0], null)
}

output networking_fixed_ip_v6 {
  value = try(openstack_networking_port_v2.gw_vip_port.all_fixed_ips[1], null)

}

output networking_floating_ip {
  value = openstack_networking_floatingip_v2.gw_vip_fip.address
}
