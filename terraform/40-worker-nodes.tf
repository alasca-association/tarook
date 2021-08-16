resource "openstack_networking_port_v2" "worker" {
  count = var.workers
  name  = "managed-k8s-worker-${try(var.worker_names[count.index], count.index)}"

  network_id = openstack_networking_network_v2.cluster_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }

  port_security_enabled = false
}

# server groups ought to be cheap so let's create one regardless of whether it's used or not
resource "openstack_compute_servergroup_v2" "server_group" {
  name = var.worker_anti_affinity_group_name
  policies = ["anti-affinity"]
}

data "openstack_compute_flavor_v2" "worker" {
  count = var.workers
  name  = try(var.worker_flavors[count.index], var.default_worker_flavor)
}

data "openstack_images_image_v2" "worker" {
  count = var.workers
  name  = try(var.worker_images[count.index], var.default_worker_image_name)
}

resource "openstack_blockstorage_volume_v2" "worker-volume" {
  count = var.create_root_disk_on_volume == true ? var.workers : 0

  name        = "managed-k8s-worker-volume-${try(var.worker_names[count.index], count.index)}"
  size        = data.openstack_compute_flavor_v2.worker[count.index].disk
  image_id    = data.openstack_images_image_v2.worker[count.index].id
  volume_type = var.root_disk_volume_type

  timeouts {
    create = var.timeout_time
    delete = var.timeout_time
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count = var.workers
  name  = openstack_networking_port_v2.worker[count.index].name

  availability_zone = var.enable_az_management ? try(var.worker_azs[count.index], var.azs[count.index % length(var.azs)]) : null
  flavor_id         = data.openstack_compute_flavor_v2.worker[count.index].id
  image_id          = var.create_root_disk_on_volume == false ? data.openstack_images_image_v2.worker[count.index].id : null
  key_pair          = var.keypair
  config_drive      = true

  dynamic scheduler_hints {
    # Abusing 'for_each' as a conditional
    for_each = try(var.worker_join_anti_affinity_group[count.index], false) == true ? ["dummy"] : []
      content {
        group = openstack_compute_servergroup_v2.server_group.id
      }
  }

  dynamic block_device {
    # Using "for_each" for check the conditional "create_root_disk_on_volume". It's not working as a loop. "dummy" should make this just more visible.
    for_each = var.create_root_disk_on_volume == true ? ["dummy"] : []
      content {
        uuid                  = openstack_blockstorage_volume_v2.worker-volume[count.index].id
        source_type           = "volume"
        boot_index            = 0
        destination_type      = "volume"
        delete_on_termination = true
      }
  }

  depends_on = [
    openstack_objectstorage_container_v1.thanos_data
  ]

  network {
    port = openstack_networking_port_v2.worker[count.index].id
  }

  # Ignoring 'scheduler_hints' here for existing VMs because otherwise tf would destroy and recreate them.
  # The initial distribution for existing clusters must therefore be enforced manually.
  lifecycle {
    ignore_changes = [key_pair, image_id, scheduler_hints]
  }
}
