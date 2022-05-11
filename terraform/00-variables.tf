# ANCHOR: terraform_variables
variable "cluster_name" {
  type = string
  default = "managed-k8s"
}

variable "haproxy_ports" {
  type = list(number)
  default = [30000, 30060]
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

variable "ssh_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
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
  default = "Ubuntu 20.04 LTS x64"
}

variable "default_worker_image_name" {
  type    = string
  default = "Ubuntu 20.04 LTS x64"
}

variable "gateway_image_name" {
  type    = string
  default = "Debian 11 (bullseye)"
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
  description = "If 'enable_az_management=true' defines which availability zones of your cloud to use to distribute the spawned server for better HA. Additionally the count of the array will define how many gateway server will be spawned. The naming of the elements doesn't matter if 'enable_az_management=false'."
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
  default = "three_times_replicated"
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

variable "worker_root_disk_sizes" {
  type = list(number)
  default = []
  description = "If 'create_root_disk_on_volume=true' and the worker flavor does not specify a disk size, the root disk volume of this particular instance will have this size."
}

variable "gateway_root_disk_volume_size" {
  type = number
  default = 10
  description = "If 'create_root_disk_on_volume=true' and the gateway flavor does not specify a disk size, the root disk volume will have this size."
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

variable "monitoring_use_thanos" {
  type = bool
  description = "Create an object storage container for thanos."
}

# ANCHOR_END: terraform_variables
