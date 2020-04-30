#!/bin/bash
set -x

current_path=$(cd $(dirname $0); pwd)
source ${current_path}/utils.sh
PASSWORD="Kylin123."

# 1. master关闭防火墙和禁用swap
[ -e /etc/sysconfig/selinux ] && sed -i 's/SELINUX=*/SELINUX=disabled/' /etc/sysconfig/selinux
swapoff -a

# 2. master节点配置ali源,并安装expect、apt-transport-https软件
[ -e /etc/apt/sources.list -a ! -e /etc/apt/sources.list.bak ] && mv /etc/apt/sources.list /etc/apt/sources.list.bak
cp ${current_path}/sources.list /etc/apt/
sleep 10
apt-get update

[ -z $(which expect) ] && apt-get install -y expect
if [[ $? -ne 0 ]]; then
  echo "安装expect失败"
  exit
fi
apt-get install -y apt-transport-https

# 3.所有节点配置ssh免密登录
for line in `cat ${current_path}/node.txt`; do
  ip=`echo $line | cut -d " " -f1`             # 提取文件中的ip
  user_name=`echo $line | cut -d " " -f2`      # 提取文件中的用户名
  check_ssh_key_exist ${ip}
done

# 4.所有节点修改主机名并配置主机名ssh免密登录
for line in `cat ${current_path}/node.txt`; do
  ip=`echo $line | cut -d " " -f1`             # 提取文件中的ip
  user_name=`echo $line | cut -d " " -f2`      # 提取文件中的用户名
  remote_exec ${ip} "hostnamectl set-hostname ${user_name}"
  remote_scp ${ip} ${current_path}/node.txt "/tmp"
  remote_exec ${ip} "cat /tmp/node.txt >> /etc/hosts"
done

# 5. 所有node节点配置软件源
declare i=0
for line in `cat ${current_path}/node.txt`; do
  if [[ $i == 0 ]]; then
    ((i++))
    continue
  fi
  ip=`echo $line | cut -d " " -f1`             # 提取文件中的ip
  user_name=`echo $line | cut -d " " -f2`      # 提取文件中的用户名
  remote_scp ${ip} ${current_path}/sources.list "/tmp"
  remote_scp ${ip} ${current_path}/configure_node.sh "/tmp"
  remote_exec ${ip} "bash /tmp/configure_node.sh >> /tmp/configure_node.log"
done

# 6.安装master
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -

cat  > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

apt-get update && apt-get install -y docker.io kubelet=1.15.2-00 kubeadm=1.15.2-00 kubectl=1.15.2-00
if [[ $? -ne 0 ]]; then
  echo "安装k8s master失败"
  exit
fi

kubeadm init --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.15.2 --pod-network-cidr=192.169.0.0/16  > ${current_path}/jion

if [[ $? -ne 0 ]]; then
  echo "安装k8s master失败"
  exit
fi

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# 7. 安装容器网络插件calico
docker load -i ${current_path}/calico/image/calico_cni.tar
docker load -i ${current_path}/calico/image/calico_node.tar

kubectl apply -f ${current_path}/calico/rbac-kdd.yaml
kubectl apply -f ${current_path}/calico/calico.yaml

# 8. 安装efk日志收集系统
docker load -i ${current_path}/logging/image/busybox.tar
docker load -i ${current_path}/logging/image/elastic643.tar
docker load -i ${current_path}/logging/image/fluentd.tar
docker load -i ${current_path}/logging/image/kibana_643.tar

kubectl apply -f ${current_path}/logging/namespace.yaml
kubectl apply -f ${current_path}/logging/es-service.yaml
kubectl apply -f ${current_path}/logging/es-statefulset.yaml

kubectl apply -f ${current_path}/logging/fluentd-es-configmap.yaml
kubectl apply -f ${current_path}/logging/fluentd-es-ds.yaml

kubectl apply -f ${current_path}/logging/kibana-deployment.yaml
kubectl apply -f ${current_path}/logging/kibana-service.yaml

# 9. 安装prometheus监控系统
docker load -i ${current_path}/monitor/image/grafana_v1.tar
docker load -i ${current_path}/monitor/image/node-exporter.tar
docker load -i ${current_path}/monitor/image/prometheus.tar

kubectl apply -f ${current_path}/monitor/namespace.yaml
kubectl apply -f ${current_path}/monitor/node-exporter.yaml


kubectl apply -f ${current_path}/monitor/grafana.yaml
kubectl apply -f ${current_path}/monitor/prometheus.yaml
