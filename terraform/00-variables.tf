# ANCHOR: terraform_variables

variable "cluster_name" {
  type = string
  default = "managed-k8s"
}

variable "subnet_cidr" {
  type = string
  default = "172.30.154.0/24"
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
  default = "shared-public-IPv4"
}

variable "keypair" {
  type = string
}

variable "default_master_image_name" {
  type    = string
  default = "Ubuntu 22.04 LTS x64"
}

variable "default_worker_image_name" {
  type    = string
  default = "Ubuntu 22.04 LTS x64"
}

variable "gateway_image_name" {
  type    = string
  default = "Debian 12 (bookworm)"
}

variable "gateway_flavor" {
  type    = string
  default = "XS"
}

variable "default_master_flavor" {
  type    = string
  default = "M"
}

variable "default_worker_flavor" {
  type    = string
  default = "M"
}

variable "azs" {
  type    = list(string)
  default = ["AZ1", "AZ2", "AZ3"]
  description = "If 'enable_az_management=true' defines which availability zones of your cloud to use to distribute the spawned server for better HA. Additionally the count of the array will define how many gateway server will be spawned. The naming of the elements doesn't matter if 'enable_az_management=false'. It is also used for unique naming of gateways."
}

variable "masters" {
  type    = number
  default = 3
}

variable "workers" {
  type    = number
  default = 4
}

variable "worker_flavors" {
  type    = list(string)
  default = []
}

variable "worker_images" {
  type    = list(string)
  default = []
}

variable "worker_azs" {
  type    = list(string)
  default = []
}

// It can be used to uniquely identify workers
variable "worker_names" {
  type    = list(string)
  default = []
}

variable "master_flavors" {
  type    = list(string)
  default = []
}

variable "master_images" {
  type    = list(string)
  default = []
}

variable "master_azs" {
  type    = list(string)
  default = []
}

// It can be used to uniquely identify masters
variable "master_names" {
  type    = list(string)
  default = []
}

variable "thanos_delete_container" {
  type    = bool
  default = false
}

// If set to false, the availability zone of instances will not be managed.
// This is useful in CI environments if the Cloud Is Full.
variable "enable_az_management" {
  type    = bool
  default = true
}

variable "create_root_disk_on_volume" {
  type = bool
  default = false
}

variable "timeout_time" {
  type = string
  default = "30m"
}

variable "root_disk_volume_type" {
  type = string
  default = ""
  description = "If 'create_root_disk_on_volume=true', the volume type to be used as default for all instances. If left empty, default of IaaS environment is used."
}

variable "worker_join_anti_affinity_group" {
  type = list(bool)
  default = []
}

variable "worker_anti_affinity_group_name" {
  type = string
  default = "cah-anti-affinity"
}

variable "master_root_disk_sizes" {
  type = list(number)
  default = []
  description = "If 'create_root_disk_on_volume=true' and the master flavor does not specify a disk size, the root disk volume of this particular instance will have this size."
}

variable "master_root_disk_volume_types" {
  type        = list(string)
  default     = []
  description = "If 'create_root_disk_on_volume=true', volume type for root disk of this particular control plane node. If 'root_disk_volume_type' is left empty, default volume type of your IaaS environment is used."
}

variable "worker_root_disk_sizes" {
  type = list(number)
  default = []
  description = "If 'create_root_disk_on_volume=true', volume type for root disk of this particular worker node. If 'root_disk_volume_type' is left empty, default volume type of your IaaS environment is used."
}

variable "worker_root_disk_volume_types" {
  type        = list(string)
  default     = []
  description = "If 'create_root_disk_on_volume=true', volume types of easdasd TODO"
}

variable "gateway_root_disk_volume_size" {
  type = number
  default = 10
  description = "If 'create_root_disk_on_volume=true' and the gateway flavor does not specify a disk size, the root disk volume will have this size."
}

variable "gateway_root_disk_volume_type" {
  type        = string
  default     = ""
  description = "If 'create_root_disk_on_volume=true', set the volume type of the root disk volume for Gateways. Can't be configured separately for each instance"
}

variable "default_master_root_disk_size" {
  type = number
  default = 50
  description = "If 'create_root_disk_on_volume=true', the master flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size."
}

variable "default_worker_root_disk_size" {
  type = number
  default = 50
  description = "If 'create_root_disk_on_volume=true', the worker flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size."
}

variable "network_mtu" {
  type = number
  default = 1450
  description = "MTU for the network used for the cluster."
}

variable "dns_nameservers_v4" {
  type = list(string)
  default = []
  description = "A list of IPv4 addresses which will be configured as DNS nameservers of the IPv4 subnet."
}

variable "monitoring_manage_thanos_bucket" {
  type = bool
  /* Although the default here is "false",
     it is actually "true" and only applied
     if Thanos is enabled so that no bucket gets created
     if not needed. That logic is set in the "update_inventory.py"-script */
  default = false
  description = "Create an object storage container for thanos."
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_backend" {
  type = bool
  default = false
  description = "If set to true, GitLab will be used as Terraform HTTP backend."
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_base_url" {
  type = string
  default = ""
  description = "Base URL of GitLab for Terraform HTTP backend if 'gitlab_backend=true'."
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_project_id" {
  type = string
  default = ""
  description = "If 'gitlab_backend=true', the Terraform state will be stored in the GitLab repo with this ID."
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_state_name" {
  type = string
  default = ""
  description = "If 'gitlab_backend=true', the terraform state file will have this name."
}

# ANCHOR_END: terraform_variables
