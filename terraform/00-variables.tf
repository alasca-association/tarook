variable "haproxy_ports" {
  type    = list(number)
  default = [30000, 30060]
}

variable "network_name" {
  type    = string
  default = "managed-k8s-network"
}

variable "subnet_name" {
  type    = string
  default = "managed-k8s-network"
}

variable "subnet_cidr" {
  type = string
}

variable "security_group_name" {
  type    = string
  default = "managed-k8s"
}

variable "ssh_security_group_name" {
  type    = string
  default = "managed-k8s-ssh"
}

variable "vpn_security_group_name" {
  type    = string
  default = "managed-k8s-vpn"
}

variable "ssh_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "gateway_security_group_name" {
  type    = string
  default = "managed-k8s-gw"
}

variable "public_network" {
  type    = string
  default = "shared-public-IPv4"
}

variable "router_name" {
  type    = string
  default = "managed-k8s-router"
}

variable "keypair" {
  type = string
}

variable "default_master_image_name" {
  type    = string
  default = "Ubuntu 18.04 LTS x64"
}

variable "default_worker_image_name" {
  type    = string
  default = "Ubuntu 18.04 LTS x64"
}

variable "gateway_image_name" {
  type    = string
  default = "Debian 10 (buster)"
}

variable "vip_port_name" {
  type    = string
  default = "vip-port"
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

variable "thanos_container_name" {
  type    = string
  default = "managed-k8s-monitoring-thanos-data"
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
  default = "ceph"
}
