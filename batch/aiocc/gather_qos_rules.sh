#!/bin/sh
#POSIX
#

#description:    gather qos rules from client nodes 
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2017-01-04
#
#运行本脚本时,假设主控制节点与所有节点(包括编译节点)已经进行SSH认证
#

#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ./__aiocc_init.sh ]; then
	echo "AIOCC Error:initialization failure:cannot find the file __aiocc_init.sh... "
	exit 1
else
	source ./__aiocc_init.sh
	echo 'AIOCC INFO:initialization completed...'
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"
clear_execute_statu_signal

#
#client节点收集本节点的qos_rules到$1
#
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${AIOCC_BATCH_DIR}/__gather_qos_rules.sh $1"
ssh_check_cluster_status "nodes_client.out" "${AIOCC_EXECUTE_STATUS_FINISHED}" 1 1
rm -f $1/*.qos_rules
#
#复制各节点$1目录下的qos_rules文件到当前节点的$1目录下
#
for host_ip in $(cat "${MULTEXU_BATCH_CONFIG_DIR}/nodes_client.out")
do 
	scp root@${host_ip}:$1/*.qos_rules $1/
done
send_execute_statu_signal "${AIOCC_EXECUTE_STATUS_FINISHED}"