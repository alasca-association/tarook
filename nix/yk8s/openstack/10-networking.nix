{
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    resource."openstack_networking_network_v2"."cluster_network" = {
      name = "${config.var.cluster_name}-network";
      admin_state_up = true;
      mtu = config.var.network_mtu;
      lifecycle = {
        ignore_changes = ["mtu"];
      };
    };

    resource."openstack_networking_router_v2"."cluster_router" = {
      name = "${config.var.cluster_name}-router";
      admin_state_up = true;
      external_network_id = lib.tfRef "data.openstack_networking_network_v2.public_network.id";
    };
  }
  (lib.mkIf config.var.ipv4_enabled {
    resource."openstack_networking_subnet_v2"."cluster_subnet" = {
      name = "${config.var.cluster_name}-network-v4";
      network_id = lib.tfRef "openstack_networking_network_v2.cluster_network.id";
      cidr = config.var.subnet_cidr;
      ip_version = 4;
      dns_nameservers = config.var.dns_nameservers_v4;
    };

    resource."openstack_networking_router_interface_v2"."cluster_router_iface" = {
      router_id = lib.tfRef "openstack_networking_router_v2.cluster_router.id";
      subnet_id = lib.tfRef "openstack_networking_subnet_v2.cluster_subnet.id";
    };
  })
  (lib.mkIf config.var.ipv6_enabled {
    resource."openstack_networking_subnet_v2"."cluster_v6_subnet" = {
      name = "${config.var.cluster_name}-network-v6";
      network_id = lib.tfRef "openstack_networking_network_v2.cluster_network.id";
      cidr = config.var.subnet_v6_cidr;
      ip_version = 6;
      ipv6_address_mode = "dhcpv6-stateful";
      ipv6_ra_mode = "dhcpv6-stateful";
    };

    resource."openstack_networking_router_interface_v2"."cluster_router_iface_v6" = {
      router_id = lib.tfRef "openstack_networking_router_v2.cluster_router.id";
      subnet_id = lib.tfRef "openstack_networking_subnet_v2.cluster_v6_subnet.id";
    };
  })
]
