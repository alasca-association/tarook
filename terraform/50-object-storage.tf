resource "openstack_objectstorage_container_v1" "thanos_data" {
  name = "${var.cluster_name}-monitoring-thanos-data"
  count = var.monitoring_manage_thanos_bucket ? 1 : 0
  force_destroy = var.thanos_delete_container
}

resource "openstack_objectstorage_container_v1" "buckets" {
  for_each = toset(var.bucket_names)
  name = each.key
  # Please use "openstack container delete <containername> -r" to delete
  # non-empty containers by hand AND make sure you don't need the
  # contained data (backups, application data, ...) any longer!
  force_destroy = false
}
