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

variable "gateway_defaults" {
  description = <<-EOT
    Default attributes for gateway nodes

    'root_disk_size' and 'root_disk_volume_type' only apply if 'create_root_disk_on_volume=true'.
    If 'root_disk_volume_type' is left empty the default of the IaaS environment will be used.
  EOT

  type = object({              # --- template spec ---
    image                      = optional(string, "Debian 12 (bookworm)")
    flavor                     = optional(string, "XS")
    root_disk_size             = optional(number, 10)
    root_disk_volume_type      = optional(string, "")
  })
  default = {                  # --- default template ---
    image                      = "Debian 12 (bookworm)"
    flavor                     = "XS"
    root_disk_size             = 10
    root_disk_volume_type      = ""
  }

  validation {
     condition     = var.gateway_defaults.root_disk_size != 0
     error_message = "Gateway 'root_disk_size' is zero"
  }
}


variable "master_defaults" {
  description = <<-EOT
    Default attributes for control plane nodes

    'root_disk_size' and 'root_disk_volume_type' only apply if 'create_root_disk_on_volume=true'.
    If 'root_disk_volume_type' is left empty the default of the IaaS environment will be used.
  EOT

  type = object({              # --- template spec ---
    image                      = optional(string, "Ubuntu 22.04 LTS x64")
    flavor                     = optional(string, "M")
    root_disk_size             = optional(number, 50)
    root_disk_volume_type      = optional(string, "")
  })
  default = {                  # --- default template ---
    image                      = "Ubuntu 22.04 LTS x64"
    flavor                     = "M"
    root_disk_size             = 50
    root_disk_volume_type      = ""
  }

  validation {
     condition     = var.master_defaults.root_disk_size != 0
     error_message = "Master 'root_disk_size' is zero"
  }
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


variable "worker_defaults" {
  description = <<-EOT
    Default attributes for worker nodes

    'root_disk_size' and 'root_disk_volume_type' only apply if 'create_root_disk_on_volume=true'.
    If 'root_disk_volume_type' is left empty the default of the IaaS environment will be used.

    Leaving 'anti_affinity_group' empty means to not join any anti affinity group
  EOT

  type = object({              # --- template spec ---
    image                      = optional(string, "Ubuntu 22.04 LTS x64")
    flavor                     = optional(string, "M")
    root_disk_size             = optional(number, 50)
    root_disk_volume_type      = optional(string, "")
    anti_affinity_group        = optional(string)
  })
  default = {                  # --- default template ---
    image                      = "Ubuntu 22.04 LTS x64"
    flavor                     = "M"
    root_disk_size             = 50
    root_disk_volume_type      = ""
  }

  validation {
     condition     = var.worker_defaults.root_disk_size != 0
     error_message = "Worker 'root_disk_size' is zero"
  }
}

variable "workers" {
  description = <<-EOT
    User defined list of worker nodes to be created with specified values

    Leaving 'anti_affinity_group' empty means to not join any anti affinity group
  EOT

  type = map(
    object({
      image                    = optional(string)
      flavor                   = optional(string)
      az                       = optional(string)
      root_disk_size           = optional(number)
      root_disk_volume_type    = optional(string)
      anti_affinity_group      = optional(string)
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
