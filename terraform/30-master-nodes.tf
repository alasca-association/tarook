locals {
  # NOTE: coalesce() is used to provide non-null default values from the templates
  master_nodes = {
    for name, values in var.nodes :
        "${local.nodes_prefix}${name}" => {
          image                    = coalesce(values.image, var.master_defaults.image)
          flavor                   = coalesce(values.flavor, var.master_defaults.flavor)
          az                       = values.az  # default: null
          volume_name              = "${var.cluster_name}-master-volume-${name}"
          root_disk_size           = values.root_disk_size != null ? values.root_disk_size : var.worker_defaults.root_disk_size != null ? var.worker_defaults.root_disk_size : null
          root_disk_volume_type    = values.root_disk_volume_type != null ? values.root_disk_volume_type : var.master_defaults.root_disk_volume_type
          create_root_disk_on_volume = coalesce(
                                        values.create_root_disk_on_volume,
                                        var.master_defaults.create_root_disk_on_volume,
                                        var.create_root_disk_on_volume
                                      )
        } if values.role == "master"
    }
  master_nodes_with_volumes = {
      for k, v in local.master_nodes : k => v
      if v.create_root_disk_on_volume == true
  }
}

resource "openstack_networking_port_v2" "master" {
  for_each = local.master_nodes
  name = each.key

  network_id = openstack_networking_network_v2.cluster_network.id

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

  port_security_enabled = false
}

data "openstack_compute_flavor_v2" "master" {
  for_each = local.master_nodes
  name     = each.value.flavor
}

data "openstack_images_image_v2" "master" {
  for_each = local.master_nodes
  name     = each.value.image
  most_recent = true
}

resource "openstack_blockstorage_volume_v3" "master-volume" {
  for_each = local.master_nodes_with_volumes

  name        = each.value.volume_name
  size        = each.value.root_disk_size != null ? each.value.root_disk_size : (data.openstack_compute_flavor_v2.worker[each.key].disk > 0) ? data.openstack_compute_flavor_v2.worker[each.key].disk : null
  image_id    = data.openstack_images_image_v2.master[each.key].id
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

resource "openstack_compute_instance_v2" "master" {
  for_each = local.master_nodes
  name     = each.key

  availability_zone = each.value.az
  config_drive      = true
  flavor_id         = data.openstack_compute_flavor_v2.master[each.key].id
  image_id          = each.value.create_root_disk_on_volume == false ? data.openstack_images_image_v2.master[each.key].id : null
  key_pair          = var.keypair

  dynamic block_device {
    # Abusing 'for_each' as a conditional
    # It's not working as a loop. The outer `each.key` is "passed" into the inner `for_each`
    for_each = each.value.create_root_disk_on_volume == true ? ["dummy"] : []
      content {
        uuid                  = openstack_blockstorage_volume_v3.master-volume[each.key].id
        source_type           = "volume"
        boot_index            = 0
        destination_type      = "volume"
        delete_on_termination = true
      }
  }

  network {
    port = openstack_networking_port_v2.master[each.key].id
  }

  lifecycle {
    ignore_changes = [key_pair, image_id, config_drive]
  }
}

output masters {
  value = openstack_compute_instance_v2.master
  sensitive = true
}
output master_ports {
  value = openstack_networking_port_v2.master
}
