resource "openstack_networking_network_v2" "cluster_network" {
  name = "${var.cluster_name}-network"
  admin_state_up = true
  mtu = var.network_mtu
  lifecycle {
    ignore_changes = [mtu]
  }
}

resource "openstack_networking_subnet_v2" "cluster_subnet" {
  # Create only if ipv4 support is enabled
  count = var.ipv4_enabled ? 1 : 0

  name = "${var.cluster_name}-network-v4"
  network_id = openstack_networking_network_v2.cluster_network.id
  cidr       = var.subnet_cidr
  ip_version = 4
  dns_nameservers = var.dns_nameservers_v4
}

resource "openstack_networking_subnet_v2" "cluster_v6_subnet" {
  # Create only if ipv6 support is enabled
  count = var.ipv6_enabled ? 1 : 0

  name = "${var.cluster_name}-network-v6"
  network_id = openstack_networking_network_v2.cluster_network.id
  cidr = var.subnet_v6_cidr
  ip_version = 6
  ipv6_address_mode = "dhcpv6-stateful"
  ipv6_ra_mode = "dhcpv6-stateful"
}

resource "openstack_networking_router_v2" "cluster_router" {
  name                = "${var.cluster_name}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public_network.id
}

resource "openstack_networking_router_interface_v2" "cluster_router_iface" {
  # Create only if ipv4 support is enabled
  count = var.ipv4_enabled ? 1 : 0

  router_id = openstack_networking_router_v2.cluster_router.id
  subnet_id = openstack_networking_subnet_v2.cluster_subnet[0].id
}

resource "openstack_networking_router_interface_v2" "cluster_router_iface_v6" {
  # Create only if ipv6 support is enabled
  count = var.ipv6_enabled ? 1 : 0

  router_id = openstack_networking_router_v2.cluster_router.id
  subnet_id = openstack_networking_subnet_v2.cluster_v6_subnet[0].id
}
