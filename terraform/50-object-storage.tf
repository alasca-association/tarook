resource "openstack_objectstorage_container_v1" "thanos_data" {
  name = "${var.cluster_name}-monitoring-thanos-data"
  count = var.monitoring_manage_thanos_bucket ? 1 : 0
  force_destroy = var.thanos_delete_container
}