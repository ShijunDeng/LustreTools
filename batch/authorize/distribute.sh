#!/bin/bash
#
#description:   a simple uniform tools for authorization
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-20
#

#声明环境变量
export PATH="/usr/lib/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"

#指定远程分发的来源与目标
from_var="${MULTEXU_BATCH_AUTHORIZE_DIR}/nodes_authorize.sh"
to_var="${MULTEXU_BATCH_AUTHORIZE_DIR}/"
#通过for循环将脚本分发到各个被管理机
for host_ip in $(cat ${MULTEXU_BATCH_CONFIG_DIR}/nodes_authorize.out)
do
    ssh -f ${host_ip} "mkdir -p ${to_var}"
    scp -o StrictHostKeyChecking=no -rp "${from_var}" "${host_ip}":"${to_var}"
done
