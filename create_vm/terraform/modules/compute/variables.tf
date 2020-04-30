variable "cluster_name" {}

variable "az_list" {
  type = list(string)
}

variable "az_list_node" {
  type = list(string)
}

variable "number_of_k8s_masters" {}

variable "number_of_k8s_nodes" {}

variable "image" {}

variable "flavor_k8s_master" {}

variable "flavor_k8s_node" {}

variable "security_groups_k8s_master" {}

variable "security_groups_k8s_node" {}

variable "network_name" {}

variable "floatingip_pool" {}
