locals {
  workers = {
    for idx in range(var.workers) :
    "${var.cluster_name}-worker-${try(var.worker_names[idx], idx)}" => {
      flavor                   = try(var.worker_flavors[idx], var.default_worker_flavor),
      image                    = try(var.worker_images[idx], var.default_worker_image_name),
      az                       = var.enable_az_management ? try(var.worker_azs[idx], var.azs[idx % length(var.azs)]) : null
      join_anti_affinity_group = try(var.worker_join_anti_affinity_group[idx], false)
      root_disk_size           = try(var.worker_root_disk_sizes[idx], var.default_worker_root_disk_size)
      root_disk_volume_type    = try(var.worker_root_disk_volume_types[idx], var.root_disk_volume_type)
      volume_name              = "${var.cluster_name}-worker-volume-${try(var.worker_names[idx], idx)}"
    }
  }
}

resource "openstack_networking_port_v2" "worker" {
  for_each = local.workers
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

# server groups ought to be cheap so let's create one regardless of whether it's used or not
resource "openstack_compute_servergroup_v2" "server_group" {
  name = var.worker_anti_affinity_group_name
  policies = ["anti-affinity"]
}

data "openstack_compute_flavor_v2" "worker" {
  for_each = local.workers
  name     = each.value.flavor
}

data "openstack_images_image_v2" "worker" {
  for_each = local.workers
  name     = each.value.image
}

resource "openstack_blockstorage_volume_v3" "worker-volume" {
  for_each = var.create_root_disk_on_volume == true ? local.workers : {}
  name        = each.value.volume_name
  size        = (data.openstack_compute_flavor_v2.worker[each.key].disk > 0) ? data.openstack_compute_flavor_v2.worker[each.key].disk : each.value.root_disk_size
  image_id    = data.openstack_images_image_v2.worker[each.key].id
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

resource "openstack_compute_instance_v2" "worker" {
  for_each = openstack_networking_port_v2.worker
  name     = each.value.name

  availability_zone = local.workers[each.key].az
  flavor_id         = data.openstack_compute_flavor_v2.worker[each.key].id
  image_id          = var.create_root_disk_on_volume == false ? data.openstack_images_image_v2.worker[each.key].id : null
  key_pair          = var.keypair
  config_drive      = true

  dynamic scheduler_hints {
    # Abusing 'for_each' as a conditional
    for_each = local.workers[each.key].join_anti_affinity_group == true ? ["dummy"] : []
      content {
        group = openstack_compute_servergroup_v2.server_group.id
      }
  }

  dynamic block_device {
    # Using "for_each" for check the conditional "create_root_disk_on_volume". It's not working as a loop. "dummy" should make this just more visible.
    for_each = var.create_root_disk_on_volume == true ? ["dummy"] : []
      content {
        uuid                  = openstack_blockstorage_volume_v3.worker-volume[each.key].id
        source_type           = "volume"
        boot_index            = 0
        destination_type      = "volume"
        delete_on_termination = true
      }
  }

  network {
    port = each.value.id
  }

  # Ignoring 'scheduler_hints' here for existing VMs because otherwise tf would destroy and recreate them.
  # The initial distribution for existing clusters must therefore be enforced manually.
  lifecycle {
    ignore_changes = [key_pair, image_id, config_drive, scheduler_hints]
  }
}
