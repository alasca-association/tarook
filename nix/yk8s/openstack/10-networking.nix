{
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s.openstack;
in {
  yk8s.terraform.modules =
    [
      {
        resource.openstack_networking_network_v2.cluster_network = [
          {
            admin_state_up = true;
            lifecycle = [
              {
                ignore_changes = [
                  "mtu"
                ];
              }
            ];
            mtu = cfg.network_mtu;
            name = "${config.yk8s.infra.cluster_name}-network";
          }
        ];
        resource.openstack_networking_router_v2.cluster_router = [
          {
            admin_state_up = true;
            external_network_id = yk8s-lib.tfRef "data.openstack_networking_network_v2.public_network.id";
            name = "${config.yk8s.infra.cluster_name}-router";
          }
        ];

        resource.openstack_networking_secgroup_v2.barndoor = [
          {
            description = "A barndoor wide open";
            name = "barndoor";
          }
        ];
      }
    ]
    ++ (lib.optional config.yk8s.infra.ipv4_enabled {
      resource.openstack_networking_router_interface_v2.cluster_router_iface = {
        _import_from = "openstack_networking_router_interface_v2.cluster_router_iface[0]";
        router_id = yk8s-lib.tfRef "openstack_networking_router_v2.cluster_router.id";
        subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_subnet.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv4-icmp-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv4-icmp-egress[0]";
        direction = "egress";
        ethertype = "IPv4";
        protocol = "icmp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv4-icmp-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv4-icmp-ingress[0]";
        direction = "ingress";
        ethertype = "IPv4";
        protocol = "icmp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv4-vrrp-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv4-vrrp-ingress[0]";
        direction = "ingress";
        ethertype = "IPv4";
        protocol = "vrrp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv4-vrrp-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv4-vrrp-egress[0]";
        direction = "egress";
        ethertype = "IPv4";
        protocol = "vrrp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv4-tcp-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv4-tcp-egress[0]";
        direction = "egress";
        ethertype = "IPv4";
        port_range_max = 0;
        port_range_min = 0;
        protocol = "tcp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv4-tcp-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv4-tcp-ingress[0]";
        direction = "ingress";
        ethertype = "IPv4";
        port_range_max = 0;
        port_range_min = 0;
        protocol = "tcp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv4-udp-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv4-udp-egress[0]";
        direction = "egress";
        ethertype = "IPv4";
        port_range_max = 0;
        port_range_min = 0;
        protocol = "udp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv4-udp-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv4-udp-ingress[0]";
        direction = "ingress";
        ethertype = "IPv4";
        port_range_max = 0;
        port_range_min = 0;
        protocol = "udp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_subnet_v2.cluster_subnet = {
        _import_from = "openstack_networking_subnet_v2.cluster_subnet[0]";
        cidr = config.yk8s.infra.subnet_cidr;
        dns_nameservers = cfg.dns_nameservers_v4;
        ip_version = 4;
        name = "${config.yk8s.infra.cluster_name}-network-v4";
        network_id = yk8s-lib.tfRef "openstack_networking_network_v2.cluster_network.id";
      };

      output.subnet_id.value = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_subnet.id";
    })
    ++ (lib.optional config.yk8s.infra.ipv6_enabled {
      resource.openstack_networking_router_interface_v2.cluster_router_iface_v6 = {
        _import_from = "openstack_networking_router_interface_v2.cluster_router_iface_v6[0]";
        router_id = yk8s-lib.tfRef "openstack_networking_router_v2.cluster_router.id";
        subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_v6_subnet.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-frag-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-frag-egress[0]";
        direction = "egress";
        ethertype = "IPv6";
        protocol = "ipv6-frag";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-frag-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-frag-ingress[0]";
        direction = "ingress";
        ethertype = "IPv6";
        protocol = "ipv6-frag";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-icmp-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-icmp-egress";
        direction = "egress";
        ethertype = "IPv6";
        protocol = "ipv6-icmp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-icmp-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-icmp-ingress[0]";
        direction = "ingress";
        ethertype = "IPv6";
        protocol = "ipv6-icmp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-vrrp-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-vrrp-ingress[0]";
        direction = "ingress";
        ethertype = "IPv6";
        protocol = "vrrp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-vrrp-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-vrrp-egress[0]";
        direction = "egress";
        ethertype = "IPv6";
        protocol = "vrrp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-opts-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-opts-egress[0]";
        direction = "egress";
        ethertype = "IPv6";
        protocol = "ipv6-opts";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-opts-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-opts-ingress[0]";
        direction = "ingress";
        ethertype = "IPv6";
        protocol = "ipv6-opts";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-route-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-route-egress[0]";
        direction = "egress";
        ethertype = "IPv6";
        protocol = "ipv6-route";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-route-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-route-ingress[0]";
        direction = "ingress";
        ethertype = "IPv6";
        protocol = "ipv6-route";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-tcp-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-tcp-egress[0]";
        direction = "egress";
        ethertype = "IPv6";
        port_range_max = 0;
        port_range_min = 0;
        protocol = "tcp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-tcp-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-tcp-ingress[0]";
        direction = "ingress";
        ethertype = "IPv6";
        port_range_max = 0;
        port_range_min = 0;
        protocol = "tcp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-udp-egress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-udp-egress[0]";
        direction = "egress";
        ethertype = "IPv6";
        port_range_max = 0;
        port_range_min = 0;
        protocol = "udp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_secgroup_rule_v2.barndoor-ipv6-udp-ingress = {
        _import_from = "openstack_networking_secgroup_rule_v2.barndoor-ipv6-udp-ingress[0]";
        direction = "ingress";
        ethertype = "IPv6";
        port_range_max = 0;
        port_range_min = 0;
        protocol = "udp";
        security_group_id = yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id";
      };

      resource.openstack_networking_subnet_v2.cluster_v6_subnet = {
        _import_from = "openstack_networking_subnet_v2.cluster_v6_subnet[0]";
        cidr = config.yk8s.infra.subnet_v6_cidr;
        ip_version = 6;
        ipv6_address_mode = "dhcpv6-stateful";
        ipv6_ra_mode = "dhcpv6-stateful";
        name = "${config.yk8s.infra.cluster_name}-network-v6";
        network_id = yk8s-lib.tfRef "openstack_networking_network_v2.cluster_network.id";
      };

      output.subnet_v6_id.value = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_v6_subnet.id";
    });
}
