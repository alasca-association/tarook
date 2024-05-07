# ANCHOR: terraform_variables

variable "cluster_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "subnet_v6_cidr" {
  type = string
  default = "fd00::/120"  # a default value is needed so
                          # terraform recognizes this variable as optional
}

variable "dualstack_support" {
  description = "If set to true, dualstack support related resources will be (re-)created"
  type = bool
}

variable "public_network" {
  type    = string
}

variable "keypair" {
  type = string
}

variable "default_master_image_name" {
  type    = string
}

variable "default_worker_image_name" {
  type    = string
}

variable "gateway_image_name" {
  type    = string
}

variable "gateway_flavor" {
  type    = string
}

variable "default_master_flavor" {
  type    = string
}

variable "default_worker_flavor" {
  type    = string
}

variable "azs" {
  type    = list(string)
}

variable "masters" {
  type    = number
}

variable "workers" {
  type    = number
}

variable "worker_flavors" {
  type    = list(string)
}

variable "worker_images" {
  type    = list(string)
}

variable "worker_azs" {
  type    = list(string)
}

// It can be used to uniquely identify workers
variable "worker_names" {
  type    = list(string)
}

variable "master_flavors" {
  type    = list(string)
}

variable "master_images" {
  type    = list(string)
}

variable "master_azs" {
  type    = list(string)
}

// It can be used to uniquely identify masters
variable "master_names" {
  type    = list(string)
}

variable "thanos_delete_container" {
  type    = bool
}

// If set to false, the availability zone of instances will not be managed.
// This is useful in CI environments if the Cloud Is Full.
variable "enable_az_management" {
  type    = bool
}

variable "create_root_disk_on_volume" {
  type = bool
}

variable "timeout_time" {
  type = string
}

variable "root_disk_volume_type" {
  type = string
}

variable "worker_join_anti_affinity_group" {
  type = list(bool)
}

variable "worker_anti_affinity_group_name" {
  type = string
}

variable "master_root_disk_sizes" {
  type = list(number)
}

variable "master_root_disk_volume_types" {
  type        = list(string)
}

variable "worker_root_disk_sizes" {
  type = list(number)
}

variable "worker_root_disk_volume_types" {
  type        = list(string)
}

variable "gateway_root_disk_volume_size" {
  type = number
}

variable "gateway_root_disk_volume_type" {
  type        = string
}

variable "default_master_root_disk_size" {
  type = number
}

variable "default_worker_root_disk_size" {
  type = number
}

variable "network_mtu" {
  type = number
}

variable "dns_nameservers_v4" {
  type = list(string)
}

variable "monitoring_manage_thanos_bucket" {
  type = bool
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_backend" {
  type = bool
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_base_url" {
  type = string
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_project_id" {
  type = string
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_state_name" {
  type = string
}

# ANCHOR_END: terraform_variables
