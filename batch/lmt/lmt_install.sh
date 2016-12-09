#!/bin/bash
# POSIX
#
#description:    install Lustre Monitoring Tool automaticlly
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-10-19
#
#initialization

sleeptime=60 #设置检测的睡眠时间
limit=10 #递减下限

cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
	echo "MULTEXU Error:initialization failure:cannot find the file __init.sh... "
	exit 1
else
	source ../ctrl/__init.sh
	echo 'MULTEXU INFO:initialization completed...'
	`${PAUSE_CMD}`
fi
source "${MULTEXU_BATCH_CRTL_DIR}"/multexu_lib.sh #调入multexu库
clear_execute_statu_signal 

#mds 的ip
mdsnode=
#Lustre Monitoring Tool management node
lmt_mgnode=
#获取参数值
function main()
{
	while :; 
	do
		case $1 in
			--mdsnode=?*)
				mdsnode=${1#*=}
				shift
				;;
			--lmt_mgnode=?*)
				lmt_mgnode=${1#*=}
				shift
				;;
			-?*)
				printf 'MULTEXU WARN: Unknown option (ignored): %s\n' "$1" >&2
				shift
				;;
			*)	# Default case: If no more options then break out of the loop.
				shift
				break
		esac
	done
	#处理参数缺省情况,mdsnode是不可缺省的，只有给出方能正确运行，否则非正常终止程序	
	if [ ! -n "${mdsnode}" ]; then
		print_message "MULTEXU_ERROR" "the parameter --mdsnode is necessary..."
		exit 1;
	fi
}

main $@

print_message "MULTEXU_INFO" "Now start to install Lustre Monitoring Tool automaticlly ..." 

#根据hosts配置文件设置个主机的hostname
cat ${MULTEXU_BATCH_CONFIG_DIR}/hosts_table | while read hosts_line; 
do 
    split_str=($hosts_line)
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${split_str[0]}  --supercmd="hostnamectl --static set-hostname ${split_str[2]} && service network restart "

done
`${PAUSE_CMD}`

#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out are going to install mysql..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_LMT_DIR}/_mysql_install.sh"
ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out finished to install mysql..."

#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out are going to install cerebro..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_LMT_DIR}/_cerebro_install.sh"
ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out finished to install cerebro..."

#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out are going to install lmt-server-agent..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_LMT_DIR}/_lmt_install.sh --server-agent"
ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out finished to install lmt-server-agent..."

#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out are going to configure /etc/host && /etc/hostfile..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_LMT_DIR}/_host_conf.sh"
ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out finished to  configure /etc/host && /etc/hostfile..."


#没有显式给出Lustre Monitoring Tool management node就默认当前节点为Lustre Monitoring Tool management node
if [ ! -n "${lmt_mgnode}" ]; then
	print_message "MULTEXU_INFO" "the Lustre Monitoring Tool management node is default..."
    
	print_message "MULTEXU_INFO" "the current node is going to install mysql..."
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal
	sh ${MULTEXU_BATCH_LMT_DIR}/_mysql_install.sh
	local_check_status "${MULTEXU_STATUS_EXECUTE}"  "${sleeptime}" "${limit}"
    
	print_message "MULTEXU_INFO" "the current node is going to install cerebro..."
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal
	sh ${MULTEXU_BATCH_LMT_DIR}/_cerebro_install.sh
	local_check_status "${MULTEXU_STATUS_EXECUTE}"  "${sleeptime}" "${limit}"

	print_message "MULTEXU_INFO" "the current node is going to install lmt-server..."
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal
	sh ${MULTEXU_BATCH_LMT_DIR}/_lmt_install.sh --server
	local_check_status "${MULTEXU_STATUS_EXECUTE}"  "${sleeptime}" "${limit}"
	
	sh ${MULTEXU_BATCH_LMT_DIR}/_configure_cerebro_conf.sh -s ${mdsnode}
    
else
    #清除信号量  避免干扰
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${lmt_mgnode} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
	print_message "MULTEXU_INFO" "the node ${lmt_mgnode} is going to install mysql..."
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${lmt_mgnode} --cmd="sh ${MULTEXU_BATCH_LMT_DIR}/_mysql_install.sh"
	ssh_check_singlenode_status ${lmt_mgnode} "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
	print_message "MULTEXU_INFO" "the node ${lmt_mgnode} finished to install mysql..."

	#清除信号量  避免干扰
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${lmt_mgnode} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
	print_message "MULTEXU_INFO" "the node ${lmt_mgnode} is going to install cerebro..."
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${lmt_mgnode} --cmd="sh ${MULTEXU_BATCH_LMT_DIR}/_cerebro_install.sh"
	ssh_check_singlenode_status ${lmt_mgnode} "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
	print_message "MULTEXU_INFO" "the node ${lmt_mgnode} finished to install cerebro..."

	#清除信号量  避免干扰
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${lmt_mgnode} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
	print_message "MULTEXU_INFO" "the node ${lmt_mgnode} is going to install lmt-server..."
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${lmt_mgnode} --cmd="sh ${MULTEXU_BATCH_LMT_DIR}/_lmt_install.sh --server"
	ssh_check_singlenode_status ${lmt_mgnode} "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
	print_message "MULTEXU_INFO" "the node ${lmt_mgnode} finished to install lmt-server..."
	
	sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${lmt_mgnode} --cmd="sh ${MULTEXU_BATCH_LMT_DIR}/_configure_cerebro_conf.sh -s ${mdsnode}"
fi

 #重启cerebrod
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="/sbin/service cerebrod restart"
if [ ! -n "${lmt_mgnode}" ]; then
    #重启cerebrod
    #/etc/init.d/cerebrod 
    /sbin/service cerebrod restart
else
    #重启cerebrod
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${lmt_mgnode} --cmd="/sbin/service cerebrod restart"
fi

print_message "MULTEXU_INFO" "finished to install Lustre Monitoring Tool..."
print_message "MULTEXU_INFO" "use the following commands to test,please..."
print_message "MULTEXU_INFO" "oss node: /usr/sbin/lmtmetric -m ost"
print_message "MULTEXU_INFO" "mds node: /usr/sbin/lmtmetric -m mdt"
print_message "MULTEXU_INFO" "lmt management node: ltop"
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
`${PAUSE_CMD}`








