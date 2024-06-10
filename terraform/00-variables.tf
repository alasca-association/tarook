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

variable "ipv6_enabled" {
  description = "If set to true, ipv6 will be used"
  type = bool
  default = false
}

variable "ipv4_enabled" {
  description = "If set to true, ipv4 will be used"
  type = bool
  default = true

  validation {
    condition     = var.ipv4_enabled
    error_message = "YAOOK/k8s Terraform does not support IPv6-only yet, see #685"
  }
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
  type    = set(string)
  default = ["AZ1", "AZ2", "AZ3"]
  description = "Defines the availability zones of your cloud to use for the creation of servers."
}

variable "thanos_delete_container" {
  type    = bool
  default = false
}

// Setting this to false is useful in CI environments if the Cloud Is Full.
variable "spread_gateways_across_azs" {
  type    = bool
  default = true
  description = "If true, spawn a gateway node in each availability zone listed in 'azs'. Otherwise leave the distribution to the cloud controller."
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

variable "worker_anti_affinity_group_name" {
  type = string
  default = "cah-anti-affinity"
}

variable "gateway_root_disk_volume_size" {
  type = number
  default = 10
  description = "If 'create_root_disk_on_volume=true' and the gateway flavor does not specify a disk size, the root disk volume will have this size."
}

variable "gateway_root_disk_volume_type" {
  type        = string
  default     = ""
  description = "If 'create_root_disk_on_volume=true', set the volume type of the root disk volume for Gateways. Can't be configured separately for each instance. If left empty, the volume type specified in 'root_disk_volume_type' will be used."
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

variable "gateway_count" {
  type = number
  default = 0  # variables can't be used here
  description = "Amount of gateway nodes to create. (default: 0 --> one for each availability zone when 'spread_gateways_across_azs=true', 3 otherwise)"
}
locals {
  gateway_count = (
    var.gateway_count == 0 ? (var.spread_gateways_across_azs ? length(var.azs) : 3)
    : var.gateway_count
  )
}

variable "masters" {
  description = "User defined list of control plane nodes to be created with specified values"

  type = map(
    object({
      image                    = optional(string)
      flavor                   = optional(string)
      az                       = optional(string)
      root_disk_size           = optional(number)
      root_disk_volume_type    = optional(string)
    })
  )
  default = {  # default: create 3 master nodes
    "0" = {}
    "1" = {}
    "2" = {}
  }
}

variable "workers" {
  description = "User defined list of worker nodes to be created with specified values"

  type = map(
    object({
      image                    = optional(string)
      flavor                   = optional(string)
      az                       = optional(string)
      root_disk_size           = optional(number)
      root_disk_volume_type    = optional(string)
      join_anti_affinity_group = optional(bool)
    })
  )
  default = {  # default: create 4 worker nodes
    "0" = {}
    "1" = {}
    "2" = {}
    "3" = {}
  }
}

# ANCHOR_END: terraform_variables
