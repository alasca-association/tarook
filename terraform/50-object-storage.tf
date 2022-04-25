resource "openstack_objectstorage_container_v1" "thanos_data" {
  name = "${var.cluster_name}-monitoring-thanos-data"
  count = var.monitoring_use_thanos ? 1 : 0
  force_destroy = var.thanos_delete_container
}

data "template_file" "final_all" {
  template = file("${path.module}/templates/object_storage.tpl")
  vars = {
    monitoring_thanos_objectstorage_container_name = var.monitoring_use_thanos ? openstack_objectstorage_container_v1.thanos_data[0].name : ""
  }
}

resource "local_file" "final_all" {
  count = var.monitoring_use_thanos ? 1 : 0
  content         = data.template_file.final_all.rendered
  filename        = "../../inventory/03_k8s_base/group_vars/all/terraform_object-storage.yaml"
  file_permission = 0640
}
