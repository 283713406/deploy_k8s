resource "openstack_compute_instance_v2" "k8s_master" {
  name              = "${var.cluster_name}-k8s-master-${count.index + 1}"
  count             = "${var.number_of_k8s_masters}"
  image_name        = "${var.image}"
  availability_zone = "${element(var.az_list, count.index)}"
  flavor_name         = "${var.flavor_k8s_master}"

  security_groups = ["${var.security_groups_k8s_master}"]

  network {
    name = "${var.network_name}"
  }
}

resource "openstack_compute_instance_v2" "k8s_node" {
  name              = "${var.cluster_name}-k8s-node-${count.index + 1}"
  count             = "${var.number_of_k8s_nodes}"
  image_name        = "${var.image}"
  availability_zone = "${element(var.az_list_node, count.index)}"
  flavor_name         = "${var.flavor_k8s_node}"

  security_groups = ["${var.security_groups_k8s_node}"]

  network {
    name = "${var.network_name}"
  }
}

resource "openstack_networking_floatingip_v2" "k8s_master" {
  count      = "${var.number_of_k8s_masters}"
  pool       = "${var.floatingip_pool}"
}

resource "openstack_networking_floatingip_v2" "k8s_node" {
  count      = "${var.number_of_k8s_nodes}"
  pool       = "${var.floatingip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "k8s_master" {
  count                 = "${var.number_of_k8s_masters}"
  instance_id           = "${element(openstack_compute_instance_v2.k8s_master.*.id, count.index)}"
  floating_ip = "${element(openstack_networking_floatingip_v2.k8s_master.*.address, count.index)}"
}

resource "openstack_compute_floatingip_associate_v2" "k8s-node" {
  count                 = "${var.number_of_k8s_nodes}"
  instance_id           = "${element(openstack_compute_instance_v2.k8s_node.*.id, count.index)}"
  floating_ip = "${element(openstack_networking_floatingip_v2.k8s_node.*.address, count.index)}"
}