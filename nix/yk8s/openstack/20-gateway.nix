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
  yk8s.terraform.modules =
    (let
      forEachGateway = nodeName: nodeValues:
        lib.recursiveUpdate {
          resource."openstack_compute_instance_v2".${nodeName} = {
            _import_from = "openstack_compute_instance_v2.gateway[\"${nodeName}\"]";
            availability_zone = nodeValues.az;
            config_drive = true;
            block_device = lib.optional nodeValues.create_root_disk_on_volume {
              boot_index = 0;
              delete_on_termination = true;
              destination_type = "volume";
              source_type = "volume";
              uuid = yk8s-lib.tfRef "openstack_blockstorage_volume_v3.${nodeValues.volume_name}.id";
            };
            flavor_id = yk8s-lib.tfRef "data.openstack_compute_flavor_v2.gateway.id";
            image_id =
              if nodeValues.create_root_disk_on_volume
              then null
              else yk8s-lib.tfRef "data.openstack_images_image_v2.gateway.id";
            key_pair = cfg.keypair;
            lifecycle = [{ignore_changes = ["key_pair" "image_id" "config_drive"];}];
            name = nodeName;
            network = [{port = yk8s-lib.tfRef "openstack_networking_port_v2.${nodeName}.id";}];
          };

          resource."openstack_networking_floatingip_associate_v2".${nodeName} = {
            _import_from = "openstack_networking_floatingip_associate_v2.gateway[\"${nodeName}\"]";
            depends_on = ["openstack_networking_router_interface_v2.cluster_router_iface"];
            floating_ip = yk8s-lib.tfRef "openstack_networking_floatingip_v2.${nodeName}.address";
            port_id = yk8s-lib.tfRef "openstack_networking_port_v2.${nodeName}.id";
          };

          resource."openstack_networking_floatingip_v2".${nodeName} = {
            _import_from = "openstack_networking_floatingip_v2.gateway[\"${nodeName}\"]";
            description = "Floating IP for gateway '${nodeName}'" + (lib.optionalString (nodeValues.az != null) " in ${nodeValues.az}");
            pool = cfg.public_network;
          };

          resource."openstack_networking_port_v2".${nodeName} = {
            _import_from = "openstack_networking_port_v2.gateway[\"${nodeName}\"]";
            allowed_address_pairs =
              [{ip_address = yk8s-lib.tfRef "openstack_networking_floatingip_v2.gw_vip_fip.fixed_ip";}]
              ++ (lib.optional config.yk8s.infra.ipv4_enabled
                {ip_address = "0.0.0.0/0";})
              ++ (lib.optionals config.yk8s.infra.ipv6_enabled [
                {ip_address = "::/0";}
                {ip_address = config.yk8s.infra.subnet_v6_cidr;}
              ]);
            depends_on = ["openstack_networking_floatingip_v2.gw_vip_fip"];
            fixed_ip =
              (lib.optional config.yk8s.infra.ipv4_enabled
                {subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_subnet.id";})
              ++ (lib.optional config.yk8s.infra.ipv6_enabled
                {subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_v6_subnet.id";});
            lifecycle = [
              {
                ignore_changes = [
                  # The allowed_address_pairs are subject to change and may get
                  # (automatically) managed or extended by something else.
                  # For example, the ch-k8s-lbaas controller manages them to
                  # allow LBaaS traffic.
                  # Terraform would reset these settings on each run if we would
                  # not ignore changes
                  "allowed_address_pairs"
                ];
              }
            ];
            name = nodeName;
            network_id = yk8s-lib.tfRef "openstack_networking_network_v2.cluster_network.id";
            port_security_enabled = true;
            security_group_ids = [
              #       Gateway nodes shall accept and forward any traffic hence we use
              #       the barndoor security group for them. (see #659)
              (yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id")
            ];
          };
        }
        (lib.optionalAttrs nodeValues.create_root_disk_on_volume {
          resource."openstack_blockstorage_volume_v3".${nodeValues.volume_name} = let
            sizeExpr =
              if nodeValues.root_disk_size != null
              then toString nodeValues.root_disk_size
              else "data.openstack_compute_flavor_v2.gateway.disk";
          in {
            _import_from = "openstack_blockstorage_volume_v3.gateway-volume[\"${nodeName}\"]";
            image_id = yk8s-lib.tfRef "data.openstack_images_image_v2.gateway.id";
            lifecycle = [
              {
                ignore_changes = ["image_id"];
                precondition = {
                  condition = yk8s-lib.tfRef "${sizeExpr} > 0";
                  error_message = "An invalid disk size has been supplied. You probably have to explicitly configure a 'root_disk_size'";
                };
              }
            ];
            name = nodeValues.volume_name;
            size = yk8s-lib.tfRef sizeExpr;
            timeouts = [
              {
                create = config.yk8s.terraform.timeout_time;
                delete = config.yk8s.terraform.timeout_time;
              }
            ];
            volume_type = nodeValues.root_disk_volume_type;
          };
        });
    in (lib.mapAttrsToList forEachGateway gateway_nodes))
    ++ (lib.singleton {
      resource.openstack_networking_floatingip_v2.gw_vip_fip = [
        {
          depends_on = ["openstack_networking_router_interface_v2.cluster_router_iface"];
          description = "Floating IP associated with the VRRP port";
          pool = cfg.public_network;
          port_id = yk8s-lib.tfRef "openstack_networking_port_v2.gw_vip_port.id";
        }
      ];

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
            name = "node_${nodeName}";
            value = {
              sensitive = true;
              value = yk8s-lib.tfRef "openstack_compute_instance_v2.${nodeName}";
            };
          })
          gateway_nodes
        )
        // (
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
    });
}
