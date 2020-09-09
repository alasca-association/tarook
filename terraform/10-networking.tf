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

resource "openstack_compute_secgroup_v2" "cluster_secgroup" {
  name        = var.security_group_name
  description = "A barndoor wide open"
  rule {
    ip_protocol = "tcp"
    from_port   = 1
    to_port     = 65535
    cidr        = "0.0.0.0/0"
  }
  rule {
    ip_protocol = "udp"
    from_port   = 1
    to_port     = 65535
    cidr        = "0.0.0.0/0"
  }
  rule {
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "ssh" {
  name        = var.ssh_security_group_name
  description = "SSH access"

  dynamic "rule" {
    for_each = var.ssh_cidrs

    content {
      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22
      cidr        = rule.value
    }
  }
}

resource "openstack_compute_secgroup_v2" "vpn" {
  name        = var.vpn_security_group_name
  description = "VPN access and ICMP ping"

  rule {
    ip_protocol = "udp"
    from_port   = 7777
    to_port     = 7777
    cidr        = "0.0.0.0/0"
  }
  // for ICMP type rules, I wish we could restrict the incoming traffic a bit,
  // however, there is a bug with the terraform OpenStack provider around setting
  // only one of `from_port`/`to_port` to -1 apparently.
  // (and from_port/to_port correspond to ICMP Type/Code respectively)
  // So we have to open up ICMP completely.
  rule {
    ip_protocol = "icmp"
    from_port   = -1
    to_port     = -1
    cidr        = "0.0.0.0/0"
  }
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
  filename        = "../inventory/03_final/group_vars/all/networking_rendered.yaml"
  file_permission = 0640
}
