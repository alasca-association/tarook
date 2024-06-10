data "openstack_networking_network_v2" "public_network" {
  name = var.public_network
}

data "openstack_compute_flavor_v2" "gateway" {
  name = var.gateway_defaults.flavor
}

data "openstack_images_image_v2" "gateway" {
  name        = var.gateway_defaults.image
  most_recent = true
}
