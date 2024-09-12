{
  lib,
  yk8s-lib,
  config,
  ...
}: let
  cfg = config.yk8s.openstack;
in {
  yk8s.terraform.modules = lib.singleton {
    data."openstack_networking_network_v2"."public_network" = {
      name = cfg.public_network;
    };

    data."openstack_compute_flavor_v2"."gateway" = {
      name = cfg.gateway_defaults.flavor;
    };

    data."openstack_images_image_v2"."gateway" = {
      name = cfg.gateway_defaults.image;
      most_recent = true;
    };

    output.floating_ip_network_id = [
      {
        value = yk8s-lib.tfRef "data.openstack_networking_network_v2.public_network.id";
      }
    ];
  };
}
