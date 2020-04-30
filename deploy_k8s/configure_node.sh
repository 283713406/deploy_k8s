#!/bin/bash
set -x

current_path=$(cd $(dirname $0); pwd)

# 1. node关闭防火墙和禁用swap
[ -e /etc/sysconfig/selinux ] && sed -i 's/SELINUX=*/SELINUX=disabled/' /etc/sysconfig/selinux
swapoff -a

# 2. node节点配置ali源,并安装apt-transport-https软件
[ -e /etc/apt/sources.list -a ! -e /etc/apt/sources.list.bak ] && mv /etc/apt/sources.list /etc/apt/sources.list.bak
cp ${current_path}/sources.list /etc/apt/

apt-get update && apt install -y apt-transport-https

# 3. 配置k8s软件源并安装docker和kubeadm
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -

cat  > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

apt-get update && apt install -y docker.io kubeadm=1.15.2-00