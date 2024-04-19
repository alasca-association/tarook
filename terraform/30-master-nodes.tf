locals {
  # NOTE: coalesce() is used to provide non-null default values from the templates
  master_nodes = {
    for name, values in var.masters :
        "${var.cluster_name}-master-${name}" => {
          image                    = coalesce(values.image, var.master_defaults.image)
          flavor                   = coalesce(values.flavor, var.master_defaults.flavor)
          az                       = values.az  # default: null
          volume_name              = "${var.cluster_name}-master-volume-${name}"
          root_disk_size           = coalesce(values.root_disk_size, var.master_defaults.root_disk_size)
          root_disk_volume_type    = values.root_disk_volume_type != null ? values.root_disk_volume_type : var.master_defaults.root_disk_volume_type
        }
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

}

resource "openstack_blockstorage_volume_v3" "master-volume" {
  for_each = var.create_root_disk_on_volume == true ? local.master_nodes : {}

  name        = each.value.volume_name
  size        = (data.openstack_compute_flavor_v2.master[each.key].disk > 0) ? data.openstack_compute_flavor_v2.master[each.key].disk : each.value.root_disk_size
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
  image_id          = var.create_root_disk_on_volume == false ? data.openstack_images_image_v2.master[each.key].id : null
  key_pair          = var.keypair

  dynamic block_device {
    # Abusing 'for_each' as a conditional
    # It's not working as a loop. The outer `each.key` is "passed" into the inner `for_each`
    for_each = var.create_root_disk_on_volume == true ? [each.key] : []
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
