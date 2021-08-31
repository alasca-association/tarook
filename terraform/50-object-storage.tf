resource "openstack_objectstorage_container_v1" "thanos_data" {
  name          = var.thanos_container_name
  force_destroy = var.thanos_delete_container
}

data "template_file" "final_all" {
  template = file("${path.module}/templates/object_storage.tpl")
  vars = {
    monitoring_thanos_objectstorage_container_name = openstack_objectstorage_container_v1.thanos_data.name
  }
}

resource "local_file" "final_all" {
  content         = data.template_file.final_all.rendered
  filename        = "../../inventory/03_k8s_base/group_vars/all/terraform_object-storage.yaml"
  file_permission = 0640
}
