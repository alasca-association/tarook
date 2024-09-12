{
  lib,
  config,
  ...
}:
lib.mkIf config.monitoring_manage_thanos_bucket {
  resource."openstack_objectstorage_container_v1"."thanos_data" = {
    name = "${config.var.cluster_name}-monitoring-thanos-data";
    force_destroy = config.var.thanos_delete_container;
  };
}
