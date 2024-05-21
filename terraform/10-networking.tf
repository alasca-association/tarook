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

resource "openstack_networking_secgroup_v2" "barndoor" {
  name        = "barndoor"
  description = "A barndoor wide open"
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv4-tcp-ingress" {
  count = var.ipv4_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 0
  port_range_max = 0
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv4-tcp-egress" {
  count = var.ipv4_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 0
  port_range_max = 0
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv4-udp-ingress" {
  count = var.ipv4_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv4"
  protocol = "udp"
  port_range_min = 0
  port_range_max = 0
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv4-udp-egress" {
  count = var.ipv4_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv4"
  protocol = "udp"
  port_range_min = 0
  port_range_max = 0
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv4-icmp-ingress" {
  count = var.ipv4_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv4"
  protocol = "icmp"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv4-icmp-egress" {
  count = var.ipv4_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv4"
  protocol = "icmp"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-tcp-ingress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv6"
  protocol = "tcp"
  port_range_min = 0
  port_range_max = 0
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-tcp-egress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv6"
  protocol = "tcp"
  port_range_min = 0
  port_range_max = 0
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-udp-ingress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv6"
  protocol = "udp"
  port_range_min = 0
  port_range_max = 0
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-udp-egress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv6"
  protocol = "udp"
  port_range_min = 0
  port_range_max = 0
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-icmp-ingress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv6"
  protocol = "ipv6-icmp"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-icmp-egress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv6"
  protocol = "ipv6-icmp"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-route-ingress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv6"
  protocol = "ipv6-route"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-route-egress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv6"
  protocol = "ipv6-route"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-frag-ingress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv6"
  protocol = "ipv6-frag"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-frag-egress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv6"
  protocol = "ipv6-frag"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-opts-ingress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv6"
  protocol = "ipv6-opts"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_rule_v2" "barndoor-ipv6-opts-egress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv6"
  protocol = "ipv6-opts"
  security_group_id = openstack_networking_secgroup_v2.barndoor.id
}

resource "openstack_networking_secgroup_v2" "ssh" {
  name        = "ssh"
  description = "SSH access"
}

resource "openstack_networking_secgroup_rule_v2" "ssh-ipv4-ingress" {
  count = var.ipv4_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = openstack_networking_secgroup_v2.ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh-ipv4-egress" {
  count = var.ipv4_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = openstack_networking_secgroup_v2.ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh-ipv6-ingress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "ingress"
  ethertype = "IPv6"
  protocol = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = openstack_networking_secgroup_v2.ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh-ipv6-egress" {
  count = var.ipv6_enabled ? 1 : 0

  direction = "egress"
  ethertype = "IPv6"
  protocol = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = openstack_networking_secgroup_v2.ssh.id
}
