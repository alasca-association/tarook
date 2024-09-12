{
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s.openstack;
  nodes =
    lib.mapAttrs' (_: value: {
      name = value.vm_name;
      inherit value;
    })
    cfg.nodes;
in {
  yk8s.terraform.modules = lib.optional cfg.enabled {
    data.openstack_compute_flavor_v2 =
      lib.mapAttrs (_: nodeValues: {
        name = nodeValues.flavor;
      })
      nodes;

    data.openstack_images_image_v2 =
      lib.mapAttrs (_: nodeValues: {
        most_recent = true;
        name = nodeValues.image;
      })
      nodes;

    # Allow keypair name to be passed via environment variable
    variable.keypair.type = "string";

    resource.openstack_compute_servergroup_v2 = builtins.foldl' (acc: policyName:
      acc
      // {
        ${policyName} = {
          _import_from = "openstack_compute_servergroup_v2.server_group[\"${policyName}\"]";
          name = policyName;
          policies = [
            "anti-affinity"
          ];
        };
      }) {} (lib.unique (builtins.filter (v: v != null) (lib.mapAttrsToList (_: v: v.anti_affinity_group) nodes)));

    resource.openstack_compute_instance_v2 =
      lib.mapAttrs (
        nodeName: nodeValues: {
          _import_from = "openstack_compute_instance_v2.${nodeValues.role}[\"${nodeName}\"]";
          availability_zone = nodeValues.az;
          config_drive = true;
          block_device = lib.optional nodeValues.create_root_disk_on_volume {
            boot_index = 0;
            delete_on_termination = true;
            destination_type = "volume";
            source_type = "volume";
            uuid = yk8s-lib.tfRef "openstack_blockstorage_volume_v3.${nodeName}.id";
          };
          scheduler_hints = lib.optional (nodeValues.anti_affinity_group != null) {
            content = [{group = "\${openstack_compute_servergroup_v2.server_group[${nodeValues.anti_affinity_group}].id}";}];
          };
          flavor_id = yk8s-lib.tfRef "data.openstack_compute_flavor_v2.${nodeName}.id";
          image_id =
            if nodeValues.create_root_disk_on_volume
            then null
            else (yk8s-lib.tfRef "data.openstack_images_image_v2.${nodeName}.id");
          key_pair = yk8s-lib.tfRef "var.keypair";
          lifecycle = [
            {
              ignore_changes = [
                "key_pair"
                "image_id"
                "config_drive"

                # Ignoring 'scheduler_hints' here for existing VMs because otherwise tf would destroy and recreate them.
                # The initial distribution for existing clusters must therefore be enforced manually.
                "scheduler_hints"
              ];
            }
          ];
          name = nodeName;
          network = [
            {
              port = yk8s-lib.tfRef "openstack_networking_port_v2.${nodeName}.id";
            }
          ];
        }
      )
      nodes;

    resource.openstack_blockstorage_volume_v3 = lib.pipe nodes [
      (lib.filterAttrs (_: nodeValues: nodeValues.create_root_disk_on_volume))
      (
        lib.mapAttrs (
          nodeName: nodeValues: let
          in {
            _import_from = "openstack_blockstorage_volume_v3.${nodeValues.role}-volume[\"${nodeName}\"]";
            image_id = yk8s-lib.tfRef "data.openstack_images_image_v2.${nodeName}.id";
            lifecycle = [
              {
                ignore_changes = ["image_id"];
                precondition = lib.optional (nodeValues.root_disk_size == null) {
                  condition = yk8s-lib.tfRef "data.openstack_compute_flavor_v2.${nodeName}.disk > 0";
                  error_message = "An invalid disk size has been supplied. You probably have to explicitly configure a 'root_disk_size'";
                };
              }
            ];
            name = "${nodeName}-volume";
            size = (
              if nodeValues.root_disk_size != null
              then toString nodeValues.root_disk_size
              else yk8s-lib.tfRef "data.openstack_compute_flavor_v2.${nodeName}.disk"
            );
            timeouts = [
              {
                create = config.yk8s.terraform.timeout_time;
                delete = config.yk8s.terraform.timeout_time;
              }
            ];
            volume_type = nodeValues.root_disk_volume_type;
          }
        )
      )
    ];

    resource.openstack_networking_port_v2 =
      lib.mapAttrs (
        nodeName: nodeValues: (
          {
            _import_from = "openstack_networking_port_v2.${nodeValues.role}[\"${nodeName}\"]";
            fixed_ip =
              (lib.optional config.yk8s.infra.ipv4_enabled {
                subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_subnet.id";
              })
              ++ (
                lib.optional config.yk8s.infra.ipv6_enabled {
                  subnet_id = yk8s-lib.tfRef "openstack_networking_subnet_v2.cluster_v6_subnet.id";
                }
              );
            name = nodeName;
            network_id = yk8s-lib.tfRef "openstack_networking_network_v2.cluster_network.id";
            port_security_enabled = nodeValues.role == "gateway";
          }
          // lib.optionalAttrs (nodeValues.role == "gateway") {
            allowed_address_pairs =
              [{ip_address = yk8s-lib.tfRef "openstack_networking_floatingip_v2.gw_vip_fip.fixed_ip";}]
              ++ (lib.optional config.yk8s.infra.ipv4_enabled
                {ip_address = "0.0.0.0/0";})
              ++ (lib.optionals config.yk8s.infra.ipv6_enabled [
                {ip_address = "::/0";}
                {ip_address = config.yk8s.infra.subnet_v6_cidr;}
              ]);
            depends_on = ["openstack_networking_floatingip_v2.gw_vip_fip"];
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
            security_group_ids = [
              #       Gateway nodes shall accept and forward any traffic hence we use
              #       the barndoor security group for them. (see #659)
              (yk8s-lib.tfRef "openstack_networking_secgroup_v2.barndoor.id")
            ];
          }
        )
      )
      nodes;

    output =
      lib.mapAttrs' (nodeName: _: {
        name = "node_${nodeName}";
        value = {
          sensitive = true;
          value = yk8s-lib.tfRef "openstack_compute_instance_v2.${nodeName}";
        };
      })
      nodes;
  };
}
