{
  lib,
  config,
  ...
}: let
  cfg = config.yk8s.openstack;
in {
  yk8s.terraform.modules = lib.optional cfg.enabled {
    resource."openstack_objectstorage_container_v1" =
      lib.optionalAttrs cfg.monitoring_manage_thanos_bucket
      {
        "thanos_data" = {
          _import_from = "openstack_objectstorage_container_v1.thanos_data[0]";
          name = "${config.yk8s.infra.cluster_name}-monitoring-thanos-data";
          force_destroy = cfg.thanos_delete_container;
        };
      };
  };
}
