#!/bin/bash
# POSIX
#
#description:    uninstall lustre 2.8.0 automaticlly
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-11-02
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

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"
clear_execute_statu_signal 

#是否需要卸载内核
skip_uninstall_kernel=0
while :;
do
    case $1 in
        --skip_uninstall_kernel=?*)
            skip_uninstall_kernel=${1#*=}
            shift
            ;;
		-?*)
            printf 'WARN: Unknown option (ignored): %s\n' "(" >&2")"
            shift
            ;;
		*)	# Default case: If no more options then break out of the loop.
			shift
			break
	esac		
done
print_message "MULTEXU_INFO" "Now start to uninstall lustre 2.8.0 ..."
#检测和节点的状态：是否可达  ssh端口22是否启用
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=nodes_all.out
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=nodes_all.out
`${PAUSE_CMD}`

#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
#置入重启之前信号量
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --send_execute_statu_signal=${MULTEXU_STATUS_REBOOT}"
#命令结点重启
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --reboot
print_message "MULTEXU_INFO" "the nodes which its ip in node_all.out are going to reboot..."
#睡眠 暂停一段时间
`${PAUSE_CMD}`
#循环检测是否重启完成
ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_REBOOT}" ${sleeptime} ${limit}
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out finished to reboot..."

#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"

#卸载lustre server
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="sh ${MULTEXU_BATCH_UNINSTALL_DIR}/lustre_uninstall_server.sh"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${MULTEXU_BATCH_UNINSTALL_DIR}/lustre_uninstall_client.sh"

ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
#清除信号量  避免干扰
if [ ${skip_uninstall_kernel} -eq 1 ];then 
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
    #卸载lustre新内核
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_UNINSTALL_DIR}/lustre_uninstall_newkernel.sh"
    ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
fi  
print_message "MULTEXU_INFO" "finish uninstalling process..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"

