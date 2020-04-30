variable "cluster_name" {
  default = "example"
}

variable "az_list" {
  description = "List of Availability Zones to use for masters in your OpenStack cluster"
  type        = list(string)
  default     = ["nova"]
}

variable "az_list_node" {
  description = "List of Availability Zones to use for nodes in your OpenStack cluster"
  type        = list(string)
  default     = ["nova"]
}

variable "number_of_k8s_masters" {
  default = 2
}

variable "number_of_k8s_nodes" {
  default = 1
}

variable "image" {
  description = "the image to use"
  default     = ""
}

variable "flavor_k8s_master" {
  description = "Use 'openstack flavor list' command to see what your OpenStack instance uses for IDs"
  default     = 3
}

variable "flavor_k8s_node" {
  description = "Use 'openstack flavor list' command to see what your OpenStack instance uses for IDs"
  default     = 3
}

variable "security_groups_k8s_master" {
  description = "name of the security groups to use"
  default     = "default"
}

variable "security_groups_k8s_node" {
  description = "name of the security groups to use"
  default     = "default"
}

variable "network_name" {
  description = "name of the internal network to use"
  default     = "internal"
}

variable "floatingip_pool" {
  description = "name of the floating ip pool to use"
  default     = "external"
}
