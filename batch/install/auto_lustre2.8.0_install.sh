#!/bin/bash
# POSIX
#
#description:    install lustre 2.8.0 automaticlly
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-23
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

#是否需要安装内核
skip_install_kernel=0
while :;
do
    case $1 in
        --skip_install_kernel=?*)
            skip_install_kernel=${1#*=}
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


print_message "MULTEXU_INFO" "Now start to install lustre 2.8.0 ..."
#检测和节点的状态：是否可达  ssh端口22是否启用
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=nodes_all.out
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=nodes_all.out
`${PAUSE_CMD}`

if [ ${skip_install_kernel} -eq 0 ];then 
    #处理安装之前的预操作 关闭SELinux 关闭防火墙等
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_INSTALL_DIR}/lustre_install_pre.sh"
    #检测上述操作是否完成
    ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" $((sleeptime/4)) ${limit}

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
    #检测和节点的状态：是否可达  ssh端口22是否启用
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=nodes_all.out
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=nodes_all.out

    #清除信号量  避免干扰
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"

    #安装lustre新内核
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_INSTALL_DIR}/lustre_install_newkernel.sh"
    ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}

    #清除信号量  避免干扰
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
    #置入重启之前信号量
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --send_execute_statu_signal=${MULTEXU_STATUS_REBOOT}"
    #命令结点重启
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --reboot
    print_message "MULTEXU_INFO" " the nodes which its ip in node_all.out are going to reboot..."
    #睡眠 暂停一段时间
    `${PAUSE_CMD}`
    `${PAUSE_CMD}`
    #循环检测是否重启完成
    ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_REBOOT}" ${sleeptime} ${limit}
    print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out finished to reboot..."
fi

print_message "MULTEXU_INFO" "now start to install lustre server and client... "
#检测和节点的状态：是否可达  ssh端口22是否启用
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=nodes_all.out
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=nodes_all.out

`${PAUSE_CMD}`
#安装lustre server
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="sh ${MULTEXU_BATCH_INSTALL_DIR}/lustre_install_server.sh"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${MULTEXU_BATCH_INSTALL_DIR}/lustre_install_client.sh"

ssh_check_cluster_status "nodes_all.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}

print_message "MULTEXU_INFO" "finish installing process..."
`${PAUSE_CMD}`
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"