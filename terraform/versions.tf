terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = ">= 2.4.0"
    }
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "~> 1.52.0"
    }
    template = {
      source = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }
  required_version = ">= 0.14"
}
