resource "openstack_networking_network_v2" "cluster_network" {
  name           = var.network_name
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "cluster_subnet" {
  name       = var.subnet_name
  network_id = openstack_networking_network_v2.cluster_network.id
  cidr       = var.subnet_cidr
  ip_version = 4
}

resource "openstack_networking_secgroup_v2" "vpn" {
  name        = var.vpn_security_group_name
  description = "VPN access and ICMP ping"
}

resource "openstack_networking_secgroup_rule_v2" "vpn_wireguard_rule" {
  security_group_id = openstack_networking_secgroup_v2.vpn.id

  direction = "ingress"
  ethertype = "IPv4"
  protocol = "udp"
  port_range_min = 7777
  port_range_max = 7777
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "vpn_icmp_echo_request_rule" {
  security_group_id = openstack_networking_secgroup_v2.vpn.id

  direction = "ingress"
  ethertype = "IPv4"
  protocol = "icmp"
  port_range_min = 0
  port_range_max = 8
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "vpn_icmp_echo_reply_rule" {
  security_group_id = openstack_networking_secgroup_v2.vpn.id

  direction = "ingress"
  ethertype = "IPv4"
  protocol = "icmp"
  port_range_min = 0
  port_range_max = 0
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_router_v2" "cluster_router" {
  name                = var.router_name
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public_network.id
}

resource "openstack_networking_router_interface_v2" "cluster_router_iface" {
  router_id = openstack_networking_router_v2.cluster_router.id
  subnet_id = openstack_networking_subnet_v2.cluster_subnet.id
}

resource "local_file" "final_networking" {
  content = templatefile("${path.module}/templates/final_networking.tpl", {
    subnet_id              = openstack_networking_subnet_v2.cluster_subnet.id,
    floating_ip_network_id = data.openstack_networking_network_v2.public_network.id,
    subnet_cidr            = openstack_networking_subnet_v2.cluster_subnet.cidr,
  })
  filename        = "../../inventory/03_final/group_vars/all/networking_rendered.yaml"
  file_permission = 0640
}
