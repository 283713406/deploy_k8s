#!/bin/bash
set -x

current_path=$(cd $(dirname $0); pwd)
regex="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\b"
PASSWORD='Kylin123.'

check_ssh_key_exist() {
    if [ -f /root/.ssh/id_rsa.pub ];then
        echo "ssh公钥秘钥文件已经存在"
        auto_ssh_copy_id $1
    else
        echo "ssh公钥秘钥文件不存在"
        create_ssh_keygen $1
    fi
}

#创建ssh key
create_ssh_keygen() {
    echo "创建ssh公钥秘钥..............."
    /usr/bin/expect <<EOF
    set timeout -1
    spawn ssh-keygen -t rsa
    expect {
    "Enter*" {send "\r";exp_continue}
    "Enter*" {send "\r";exp_continue}
    "Enter*" {send "\r";exp_continue}
    }
EOF
    auto_ssh_copy_id $1
}

#执行ssh-copy-id的命令
auto_ssh_copy_id() {
    /usr/bin/expect <<EOF
    set timeout -1
    spawn ssh-copy-id -f $1
    expect {
    "*password*" {send "${PASSWORD}\r";exp_continue}
    }
EOF
}

case $1 in
   create)
     echo "现在开始创建k8s集群所需的虚拟机"
     # 创建k8s集群所需的虚拟机
     chmod +x ${current_path}/.terraform/plugins/linux_amd64/terraform-provider-openstack_v1.27.0_x4
     bash ${current_path}/create_vm/create_vm.sh
     ${current_path}/create_vm/bin/terraform output > ${current_path}/output.txt

     [ -e ${current_path}/deploy_k8s/node.txt ] && rm -f ${current_path}/deploy_k8s/node.txt
     declare i=0
     while read line; do
       is_ip=`echo ${line} | egrep ${regex} | wc -l`
       if [ ${is_ip} -ne 0 ]; then
         ip=`echo ${line}|cut -d "\"" -f2`
         if [[ $i == 0 ]]; then
           echo "${ip} kube-master" >> ${current_path}/deploy_k8s/node.txt
           ((i++))
         else
           echo "${ip} kube-node${i}" >> ${current_path}/deploy_k8s/node.txt
           ((i++))
         fi
       else
         continue
       fi
     done < ${current_path}/output.txt

     if [[ -e ${current_path}/deploy_k8s/node.txt ]]; then
       echo "k8s集群所需的虚拟机创建成功"
     else
       echo "k8s集群所需的虚拟机创建失败"
       exit
     fi

#     # k8s_master_fips = [ "192.168.84.123", ] k8s_node_fips = [ "192.168.84.127", ]
#     # k8s_master_fips = [ "192.168.84.145", "192.168.84.144", ] k8s_node_fips = []
#     k8s_master_fips_tmp=`echo ${output#*k8s_master_fips = [ }`
#     k8s_master_fip=`echo ${k8s_master_fips_tmp%, ] k8s_node_fips*}`
#     check_ssh_key_exist ${k8s_master_fip}
#
#     k8s_node_fips_tmp=`echo ${output#*k8s_node_fips = [}`
#     k8s_node_fips=`echo ${k8s_node_fips_tmp%]*}`
#     if [[ ${k8s_node_fips} =~ ',' ]]; then
#        touch ${current_path}/deploy_k8s/node.txt
#        echo "${k8s_master_fip} kube-master" >> ${current_path}/deploy_k8s/node.txt
#        OLD_IFS="$IFS"
#        IFS=", "
#        arr=(${k8s_node_fips})
#        IFS="$OLD_IFS"
#        declare i=1
#        for node_ip in ${k8s_node_fips[@]};do
#          echo ">>> ${node_ip}"
#          ip=`echo ${node_ip%,*}`
#          echo "${ip} kube-node${i}" >> ${current_path}/deploy_k8s/node.txt
#          ((i++))
#        done
#      else
#        echo "k8s_node_fips is null"
#      fi
      k8s_master_fip=`head -n +1 ${current_path}/deploy_k8s/node.txt | cut -d " " -f1`
      sleep 15
      check_ssh_key_exist ${k8s_master_fip}
      ssh ${k8s_master_fip} "ls" > /dev/null 2>&1
      if [[ $? -ne 0 ]]; then
        echo "配置k8s master节点ssh免密失败"
        exit
      fi
      cmd="mkdir -p /home/k8s"
      ssh root@${k8s_master_fip} ${cmd}
      scp -r ${current_path}/deploy_k8s root@${k8s_master_fip}:/home/k8s
      ssh root@${k8s_master_fip} "bash /home/k8s/deploy_k8s/deploy_k8s.sh >> /home/k8s/deploy_k8s/deploy_k8s.log"
   ;;
   destroy)
     echo "现在开始销毁k8s集群所需的虚拟机"
     # 创建k8s集群所需的虚拟机
     bash ${current_path}/create_vm/destroy_vm.sh
   ;;
   *)
     echo "Ignorant..."
   ;;
esac