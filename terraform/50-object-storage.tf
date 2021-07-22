resource "openstack_objectstorage_container_v1" "thanos_data" {
  name          = var.thanos_container_name
  force_destroy = var.thanos_delete_container
}

data "template_file" "final_all" {
  template = file("${path.module}/templates/final_all.tpl")
  vars = {
    monitoring_thanos_objectstorage_container_name = openstack_objectstorage_container_v1.thanos_data.name
  }
}

resource "local_file" "final_all" {
  content         = data.template_file.final_all.rendered
  filename        = "../../inventory/03_final/group_vars/all/rendered.yaml"
  file_permission = 0640
}
