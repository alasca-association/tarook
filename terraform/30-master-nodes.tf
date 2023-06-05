locals {
  masters = {
    for idx in range(var.masters) :
    "${var.cluster_name}-master-${try(var.master_names[idx], idx)}" => {
      flavor         = try(var.master_flavors[idx], var.default_master_flavor),
      image          = try(var.master_images[idx], var.default_master_image_name),
      az             = var.enable_az_management ? try(var.master_azs[idx], var.azs[idx % length(var.azs)]) : null
      root_disk_size = try(var.master_root_disk_sizes[idx], var.default_master_root_disk_size)
      root_disk_volume_type = try(var.master_root_disk_volume_types[idx], var.root_disk_volume_type)
      volume_name    = "${var.cluster_name}-master-volume-${try(var.master_names[idx], idx)}"
    }
  }
}

resource "openstack_networking_port_v2" "master" {
  for_each = local.masters
  name = each.key

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

data "openstack_compute_flavor_v2" "master" {
  for_each = local.masters
  name     = each.value.flavor
}

data "openstack_images_image_v2" "master" {
  for_each = local.masters
  name     = each.value.image

}

resource "openstack_blockstorage_volume_v2" "master-volume" {
  for_each = var.create_root_disk_on_volume == true ? local.masters : {}

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
  for_each = openstack_networking_port_v2.master
  name     = each.value.name

  availability_zone = local.masters[each.key].az
  config_drive      = true
  flavor_id         = data.openstack_compute_flavor_v2.master[each.key].id
  image_id          = var.create_root_disk_on_volume == false ? data.openstack_images_image_v2.master[each.key].id : null
  key_pair          = var.keypair

  dynamic block_device {
    # Using "for_each" for check the conditional "create_root_disk_on_volume". It's not working as a loop. "dummy" should make this just more visible.
    for_each = var.create_root_disk_on_volume == true ? ["dummy"] : []
      content {
        uuid                  = openstack_blockstorage_volume_v2.master-volume[each.key].id
        source_type           = "volume"
        boot_index            = 0
        destination_type      = "volume"
        delete_on_termination = true
      }
  }

  network {
    port = each.value.id
  }

  lifecycle {
    ignore_changes = [key_pair, image_id]
  }
}
