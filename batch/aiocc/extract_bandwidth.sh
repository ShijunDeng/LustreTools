#!/bin/sh
#POSIX
#

#description:    extract bandwidth from client nodes 
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2017-01-05
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
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${AIOCC_BATCH_DIR}/__extract_bandwidth.sh $1"
ssh_check_cluster_status "nodes_client.out" "${AIOCC_EXECUTE_STATUS_FINISHED}"  1 1

read_bandwidth=0
write_bandwidth=0
bandwidth=0
bandwidth_record=""
COUNT=0
#统计T次
T=5
if [ -z "$1" ];then
	print_message "MULTEXU_ERROR" "parameter missing..."
	exit 1
fi
while [ $COUNT -lt $T ];
do
	rm -f $1/*.qos_rules
	#
	#复制各节点$1目录下的qos_rules文件到当前节点的$1目录下
	#
	for host_ip in $(cat "${MULTEXU_BATCH_CONFIG_DIR}/nodes_client.out")
	do 
		scp root@${host_ip}:$1/*.import $1/
	done

	IMPORT_FILE_ARRY=($(ls $1/*.import))
	IMPORT_FILE_NUM=${IMPORT_FILE_ARRY}
	cd $1

	for FILE in ${IMPORT_FILE_ARRY[*]}
	do
		read_bandwidth=$(grep 'read_bandwidth' ${FILE} | cut -d : -f 2)
		write_bandwidth=$(grep 'write_bandwidth' ${FILE} | cut -d : -f 2 ))
		bw=(( ${read_bandwidth}+${write_bandwidth} ))
		bandwidth_record="${bandwidth_record} ${bw}"
	done
	(( COUNT+=1 ))
done
echo ${bandwidth_record} $1/bandwidth.record

python $1/bandwidth_statistic.py $1/bandwidth.record $1/bandwidth.statistic
#echo ${read_bandwidth}
#echo ${write_bandwidth}
#echo $(( (${read_bandwidth}+ ${write_bandwidth})/(${IMPORT_FILE_NUM}*${T}) )) > $1/realtime_avg.bandwidth
#echo "scale=2;(${read_bandwidth}+ ${write_bandwidth})/(${IMPORT_FILE_NUM}*${T})" | bc > $1/realtime_avg.bandwidth

send_execute_statu_signal "${AIOCC_EXECUTE_STATUS_FINISHED}"



