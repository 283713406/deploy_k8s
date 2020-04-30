provider "openstack" {
  version = "~> 1.17"
}

module "compute" {
  source = "./modules/compute"

  cluster_name                                 = "${var.cluster_name}"
  az_list                                      = "${var.az_list}"
  az_list_node                                 = "${var.az_list_node}"
  number_of_k8s_masters                        = "${var.number_of_k8s_masters}"
  number_of_k8s_nodes                          = "${var.number_of_k8s_nodes}"
  image                                        = "${var.image}"
  flavor_k8s_master                            = "${var.flavor_k8s_master}"
  flavor_k8s_node                              = "${var.flavor_k8s_node}"
  security_groups_k8s_master                   = "${var.security_groups_k8s_master}"
  security_groups_k8s_node                     = "${var.security_groups_k8s_node}"
  network_name                                 = "${var.network_name}"
  floatingip_pool                              = "${var.floatingip_pool}"

}

output "k8s_master_fips" {
  value = "${module.compute.k8s_master_fips}"
}

output "k8s_node_fips" {
  value = "${module.compute.k8s_node_fips}"
}