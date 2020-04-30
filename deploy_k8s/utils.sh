#!/bin/bash
set -x

remote_exec() {
    ip=$1
    cmd=$2
    ssh -o StrictHostKeyChecking=no ${ip} ${cmd}
}

remote_scp() {
    ip=$1
    source=$2
    destination=$3
    scp ${source} ${ip}:${destination}
}

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
    "*(yes/no)*" {send "yes\r";exp_continue}
    "*password*" {send "${PASSWORD}\r";exp_continue}
    }
EOF
}


