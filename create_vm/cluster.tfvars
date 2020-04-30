# your Kubernetes cluster name here
cluster_name = "test"

# list of availability zones available in your OpenStack cluster
az_list = ["x86-compute"]
az_list_node = ["x86-compute"]

# image to use for bastion, masters, standalone etcd instances, and nodes
image = "ubuntu_16_04_2_server_amd64_build0620"

# masters
number_of_k8s_masters = 1
security_groups_k8s_master = "default"
flavor_k8s_master = "m1.large"

# nodes
number_of_k8s_nodes = 2
security_groups_k8s_node = "default"
flavor_k8s_node = "m1.large"

# networking
network_name = "mynet"

floatingip_pool = "flat"

