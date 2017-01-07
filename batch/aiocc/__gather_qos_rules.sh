#!/bin/sh
#POSIX
#

#description:    client nodes gather qos_rules from ${LUSTRE_PROC_OSC} directory
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

LUSTRE_PROC_OSC="/proc/fs/lustre/osc"
OSC_ARRAY=($(ls ${LUSTRE_PROC_OSC}))

rm -f  $1/*.qos_rules

for OSC in ${OSC_ARRAY[*]}
do
	cp ${LUSTRE_PROC_OSC}/${OSC}/qos_rules $1/${HOSTNAME}_${OSC}.qos_rules
done
send_execute_statu_signal "${AIOCC_EXECUTE_STATUS_FINISHED}"