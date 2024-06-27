variable "cluster_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "subnet_v6_cidr" {
  type = string
}

variable "ipv6_enabled" {
  type = bool
  default = false
}

variable "ipv4_enabled" {
  type = bool
}

variable "public_network" {
  type    = string
}

variable "keypair" {
  type = string
}

variable "azs" {
  type    = set(string)
}

variable "thanos_delete_container" {
  type    = bool
}

// Setting this to false is useful in CI environments if the Cloud Is Full.
variable "spread_gateways_across_azs" {
  type    = bool
}

variable "create_root_disk_on_volume" {
  type = bool
}

variable "timeout_time" {
  type = string
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
  default = false
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_base_url" {
  type = string
  default = ""
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_project_id" {
  type = string
  default = ""
}

# tflint-ignore: terraform_unused_declarations
variable "gitlab_state_name" {
  type = string
  default = ""
}


variable "gateway_count" {
  type = number
}

variable "gateway_defaults" {
  type = object({              # --- template spec ---
    common_name                = string
    image                      = string
    flavor                     = string
    root_disk_size             = number
    root_disk_volume_type      = string
  })
}

variable "master_defaults" {
  type = object({              # --- template spec ---
    image                      = string
    flavor                     = string
    root_disk_size             = number
    root_disk_volume_type      = string
  })
}

variable "worker_defaults" {
  type = object({              # --- template spec ---
    image                      = string
    flavor                     = string
    root_disk_size             = number
    root_disk_volume_type      = string
    anti_affinity_group        = optional(string)
  })
}


variable "nodes" {
  type = map(
    object({
      role                     = string            # one of: 'master', 'worker'
      image                    = optional(string)
      flavor                   = optional(string)
      az                       = optional(string)
      root_disk_size           = optional(number)
      root_disk_volume_type    = optional(string)
      anti_affinity_group      = optional(string)
    })
  )
}

locals {
  nodes_prefix = (var.cluster_name == "" ? "" : "${var.cluster_name}-")
}
