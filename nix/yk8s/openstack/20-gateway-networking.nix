{
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s.openstack;
  gateway_nodes =
    lib.mapAttrs' (
      name: value: {
        name = value.vm_name;
        inherit value;
      }
    )
    (lib.filterAttrs (_: v: v.role == "gateway") cfg.nodes);
in {
  yk8s.terraform.modules = lib.optional cfg.enabled {
    resource."openstack_networking_floatingip_associate_v2" =
      lib.mapAttrs (
        nodeName: _: {
          _import_from = "openstack_networking_floatingip_associate_v2.gateway[\"${nodeName}\"]";
          depends_on = ["openstack_networking_router_interface_v2.cluster_router_iface"];
          floating_ip = yk8s-lib.tfRef "openstack_networking_floatingip_v2.${nodeName}.address";
          port_id = yk8s-lib.tfRef "openstack_networking_port_v2.${nodeName}.id";
        }
      )
      gateway_nodes;

    resource."openstack_networking_floatingip_v2" =
      (lib.mapAttrs (
          nodeName: nodeValues: {
            _import_from = "openstack_networking_floatingip_v2.gateway[\"${nodeName}\"]";
            description = "Floating IP for gateway '${nodeName}'" + (lib.optionalString (nodeValues.az != null) " in ${nodeValues.az}");
            pool = cfg.public_network;
          }
        )
        gateway_nodes)
      // {
        gw_vip_fip = [
          {
            depends_on = ["openstack_networking_router_interface_v2.cluster_router_iface"];
            description = "Floating IP associated with the VRRP port";
            pool = cfg.public_network;
            port_id = yk8s-lib.tfRef "openstack_networking_port_v2.gw_vip_port.id";
          }
        ];
      };

    resource.openstack_networking_port_v2.gw_vip_port = [
      {
        admin_state_up = true;
        fixed_ip =
          (lib.optional config.yk8s.infra.ipv4_enabled
            {subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_subnet.id";})
          ++ (lib.optionals config.yk8s.infra.ipv6_enabled [
            {subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_v6_subnet.id";}
            {subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_v6_subnet.id";}
          ]);
        name = "${config.yk8s.infra.cluster_name}-gateway-vip";
        network_id = yk8s-lib.tfRef "openstack_networking_network_v2.cluster_network.id";
        port_security_enabled = true;
        security_group_ids = [
          (yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id")
        ];
      }
    ];

    output =
      (
        lib.mapAttrs' (nodeName: _: {
          name = "floatingip_${nodeName}";
          value.value = yk8s-lib.tfRef "openstack_networking_floatingip_v2.${nodeName}";
        })
        gateway_nodes
      )
      // (lib.optionalAttrs config.yk8s.infra.ipv4_enabled {
        networking_fixed_ip = [{value = yk8s-lib.tfRef "openstack_networking_port_v2.gw_vip_port.all_fixed_ips[0]";}];
        networking_floating_ip = [{value = yk8s-lib.tfRef "openstack_networking_floatingip_v2.gw_vip_fip.address";}];
        subnet_cidr = [{value = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_subnet.cidr";}];
      })
      // (lib.optionalAttrs config.yk8s.infra.ipv6_enabled {
        networking_fixed_ip_v6 = [{value = yk8s-lib.tfRef "openstack_networking_port_v2.gw_vip_port.all_fixed_ips[1]";}];
        subnet_v6_cidr = [{value = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_v6_subnet.cidr";}];
      });
  };
}
