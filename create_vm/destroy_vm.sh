#!/bin/bash
set -x

current_path=$(cd $(dirname $0); pwd)
source ${current_path}/admin-openrc.sh

/usr/bin/expect <<EOF
set timeout -1
spawn ${current_path}/bin/terraform destroy -var-file=${current_path}/cluster.tfvars ${current_path}/terraform/
expect {
"Enter a value*" {send "yes\r";exp_continue}
}
EOF

