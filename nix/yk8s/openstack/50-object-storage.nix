{
  lib,
  config,
  ...
}: let
  cfg = config.yk8s.openstack;
in {
  yk8s.terraform.modules = lib.singleton {
    resource."openstack_objectstorage_container_v1"."thanos_data" = lib.optional cfg.monitoring_manage_thanos_bucket {
      _import_from = "openstack_objectstorage_container_v1.thanos_data[0]";
      name = "${config.yk8s.infra.cluster_name}-monitoring-thanos-data";
      force_destroy = cfg.thanos_delete_container;
    };
  };
}
