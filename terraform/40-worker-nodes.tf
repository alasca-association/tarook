resource "openstack_networking_port_v2" "worker" {
  count = var.workers
  name = "managed-k8s-worker-${try(var.worker_names[count.index], count.index)}"

  network_id = openstack_networking_network_v2.cluster_network.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
  }

  security_group_ids = [
    data.openstack_networking_secgroup_v2.default.id,
    openstack_compute_secgroup_v2.cluster_secgroup.id
  ]
}

data "openstack_compute_flavor_v2" "worker" {
  count = var.workers
  name = try(var.worker_flavors[count.index], var.default_worker_flavor)
}

data "openstack_images_image_v2" "worker" {
  count = var.workers
  name = try(var.worker_images[count.index], var.default_worker_image_name)
}

resource "openstack_compute_instance_v2" "worker" {
  count = var.workers
  name = openstack_networking_port_v2.worker[count.index].name

  availability_zone = try(var.worker_azs[count.index], var.azs[count.index % length(var.azs)])
  flavor_id = data.openstack_compute_flavor_v2.worker[count.index].id
  image_id = data.openstack_images_image_v2.worker[count.index].id
  key_pair = var.keypair
  config_drive = true

  depends_on = [
    openstack_objectstorage_container_v1.thanos_data
  ]

  network {
    port = openstack_networking_port_v2.worker[count.index].id
  }

  lifecycle {
      ignore_changes = [key_pair]
  }
}
