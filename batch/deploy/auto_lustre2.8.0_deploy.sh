#!/bin/bash
# POSIX
#
#description:    deploy lustre filesystem automaticly
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-24
#
#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
        echo "MULTEXU Error:multexu initialization failure:cannot find the file __init.sh... "
        exit 1
else
        source ../ctrl/__init.sh
fi

source "${MULTEXU_BATCH_CRTL_DIR}"/multexu_lib.sh #调入multexu库
clear_execute_statu_signal 

sleeptime=60 #设置检测的睡眠时间
limit=10 #递减下限
#文件系统所在的设备名称
devname=
#lustre将要挂载的分区的索引号:devname指定的设备上的分区
devindex=
#mds 的ip
mdsnode=
#
#获取参数值
function get_parameters()
{
	while :; 
	do
		case $1 in
			--devname=?*)
				devname=${1#*=}
				shift
				;;
			--mdsnode=?*)
				mdsnode=${1#*=}
				shift
				;;
			--devindex=?*)
				devindex=${1#*=}
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
	#处理参数缺省情况,devname和mdsnode都是不可缺省的，只有二者都给出方能正确运行，否则非正常终止程序
	if [ ! -n "${devname}" ]; then
		print_message "MULTEXU_ERROR" "the parameter --devname is necessary..."
		exit 1;
	fi
	
	if [ ! -n "${mdsnode}" ]; then
		print_message "MULTEXU_ERROR" "the parameter --mdsnode is necessary..."
		exit 1;
	fi
	
	if [ ! -n "${devindex}" ]; then
		print_message "MULTEXU_ERROR" "the parameter --devindex is necessary..."
		exit 1;
	fi
}
###############
get_parameters $@
###############

print_message "MULTEXU_INFO" "Now start to install lustre 2.8.0 ..."
#检测和节点的状态：是否可达  ssh端口22是否启用
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=nodes_all.out
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=nodes_all.out
`${PAUSE_CMD}`
#卸载指定位置上已有的lustre文件系统(防止以前在该指定设备上装过lustre文件系统)
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="umount -t lustre ${devname}${devindex}"
#同样的原因,卸载client
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="umount -t lustre /mnt/lustre"

`${PAUSE_CMD}`
`${PAUSE_CMD}`

#卸载分区以重新格式化分区
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="parted ${devname} rm ${devindex}"

`${PAUSE_CMD}`
`${PAUSE_CMD}`
`${PAUSE_CMD}`
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

#检测和节点的状态：是否可达  ssh端口22是否启用
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=nodes_all.out
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=nodes_all.out


#在server node 分区
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="sh ${MULTEXU_BATCH_DEPLOY_DIR}/__auto_parted.sh -d ${devname} -i ${devindex}"
ssh_check_cluster_status "nodes_server.out" "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_server.out finished to part ${devname}${devindex}..."
#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
#置入重启之前信号量
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --send_execute_statu_signal=${MULTEXU_STATUS_REBOOT}"
#命令结点重启
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --reboot
print_message "MULTEXU_INFO" "the nodes which its ip in node_all.out are going to reboot..."
#睡眠 暂停一段时间

`${PAUSE_CMD}`

#循环检测是否重启完成
ssh_check_cluster_status "nodes_server.out" "${MULTEXU_STATUS_REBOOT}" "${sleeptime}" "${limit}"
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out finished to reboot..."

#格式化server上的devname设备为ext4
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="y | mkfs.ext4 ${devname}"

#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"

#关闭防火墙
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="systemctl stop iptables"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="service iptables save"
print_message "MULTEXU_INFO" "the nodes which its ip in nodes_all.out closed the Firewall..."
`${PAUSE_CMD}`


#配置mgs node
print_message "MULTEXU_INFO" "configure mdsnode[${mdsnode}] ..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${mdsnode} --cmd="sh ${MULTEXU_BATCH_DEPLOY_DIR}/__configure_mdsnode.sh -d ${devname}${devindex} -i 0 -m mdt"
ssh_check_singlenode_status "${mdsnode}" "${MULTEXU_STATUS_EXECUTE}"  $((sleeptime/4)) "${limit}"
print_message "MULTEXU_INFO" "finished configuring mdsnode[${mdsnode}] ..."
#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_server.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"

#配置oss node
print_message "MULTEXU_INFO" "configure oss nodes..."
sh ${MULTEXU_BATCH_DEPLOY_DIR}/_configure_ossnode.sh -s ${mdsnode} -m ost  -d "${devname}${devindex}"
ssh_check_cluster_status "nodes_oss.out" "${MULTEXU_STATUS_EXECUTE}"  $((sleeptime/4)) "${limit}"
print_message "MULTEXU_INFO" "finished configuring oss nodes ..."
#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_oss.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"

#配置client node
print_message "MULTEXU_INFO" "configure client nodes..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${MULTEXU_BATCH_DEPLOY_DIR}/__configure_clientnode.sh -s ${mdsnode} -m lustre"
ssh_check_cluster_status "nodes_client.out" "${MULTEXU_STATUS_EXECUTE}"  $((sleeptime/2)) "${limit}"
print_message "MULTEXU_INFO" "finished configuring client nodes ..."
#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "the lustre filesystem has been established..."
exit 0
