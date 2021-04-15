resource "openstack_networking_port_v2" "master" {
  count = var.masters
  name  = "managed-k8s-master-${try(var.master_names[count.index], count.index)}"

  network_id = openstack_networking_network_v2.cluster_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }

  port_security_enabled = false
}

data "openstack_compute_flavor_v2" "master" {
  count = var.masters
  name  = try(var.master_flavors[count.index], var.default_master_flavor)
}

data "openstack_images_image_v2" "master" {
  count = var.masters
  name  = try(var.master_images[count.index], var.default_master_image_name)

}

resource "openstack_blockstorage_volume_v2" "master-volume" {
  count = var.boot_from_volume == true ? var.masters : null
  name     = "managed-k8s-master-volume-${try(var.master_names[count.index], count.index)}"
  size     = data.openstack_compute_flavor_v2.master[count.index].disk
  image_id = data.openstack_images_image_v2.master[count.index].id

  timeouts {
    create = var.timeout_time
    delete = var.timeout_time
  }
}

resource "openstack_compute_instance_v2" "master" {
  count = var.boot_from_volume == false ? var.masters : null
  name  = openstack_networking_port_v2.master[count.index].name

  availability_zone = var.enable_az_management ? try(var.master_azs[count.index], var.azs[count.index % length(var.azs)]) : null
  config_drive      = true
  flavor_id         = data.openstack_compute_flavor_v2.master[count.index].id
  image_id          = data.openstack_images_image_v2.master[count.index].id
  key_pair          = var.keypair

  depends_on = [
    openstack_objectstorage_container_v1.thanos_data
  ]

  network {
    port = openstack_networking_port_v2.master[count.index].id
  }

  lifecycle {
    ignore_changes = [key_pair, image_id]
  }
}

resource "openstack_compute_instance_v2" "boot-master" {
  count = var.boot_from_volume == true ? var.masters : null
  name  = openstack_networking_port_v2.master[count.index].name

  availability_zone = var.enable_az_management ? try(var.master_azs[count.index], var.azs[count.index % length(var.azs)]) : null
  config_drive      = true
  flavor_id         = data.openstack_compute_flavor_v2.master[count.index].id
  key_pair          = var.keypair

  block_device {
    uuid                  = openstack_blockstorage_volume_v2.master-volume[count.index].id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  depends_on = [
    openstack_objectstorage_container_v1.thanos_data
  ]

  network {
    port = openstack_networking_port_v2.master[count.index].id
  }

  lifecycle {
    ignore_changes = [key_pair, image_id]
  }
}
