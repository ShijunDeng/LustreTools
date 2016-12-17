#!/bin/bash
# POSIX
#
#description:    compile-->install-->deploy lustre 2.8.0 automaticlly
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-11-02
#
#运行本脚本时,假设主控制节点与所有节点(包括编译节点)已经进行SSH认证
#

sleeptime=60 #设置检测的睡眠时间
limit=10 #递减下限

#计算程序运行的时间
start_time=$(date +%s%N)
start_time_ms=${start_time:0:16}

#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f __init.sh ]; then
	echo "MULTEXU Error:initialization failure:cannot find the file __init.sh... "
	exit 1
else
	source ./__init.sh
	echo 'MULTEXU INFO:initialization completed...'
	`${PAUSE_CMD}`
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"

print_message "MULTEXU_INFO" "Now start to compile-->install-->deploy lustre 2.8.0 ..."
#基准目录
base_dir=${MULTEXU_BASE_DIR}
#kvm节点备份目录 备份节点配置：IP,root权限密码,免密码登陆认证,常用的个性化配置(屏幕、电源),
kvm_source_bakpath=/home/ca21/DevelopmentFiles
#kvm资源文件目录
kvm_source_path=/home/ca21/Downloads
#lustre文件系统节点机器的名称
kvm_nodes_name_lustre=("centos7.0-c1" "centos7.0-c2" "centos7.0-c3" "centos7.0-c4" "centos7.0-c5" "centos7.0-c6" "centos7.0-c7")
#lustre文件系统节点机器的资源名称
kvm_source_name_lustre=("centos7-c1.qcow2" "centos7-c2.qcow2" "centos7-c3.qcow2" "centos7-c4.qcow2" "centos7-c5.qcow2" "centos7-c6.qcow2" "centos7-c7.qcow2")
#进行编译工作机器节点的名称
kvm_node_name_dev="centosdev"
kvm_source_name_dev="centosdev.qcow2"
#编译节点
compile_node_ip=192.168.122.101
#当前节点ip
current_node_ip=192.168.122.181
#lustre部署信息
mdsnode=192.168.122.15
devname=/dev/vda 
devindex=7


#########################################################
#                   参数选项
#########################################################

#是否需要编译内核:
#   skip_build_kernel=1表示不进行内核的编译安装工作,即假设所有节点(包括编译节点)都是安装了Lustre对应内核的;
#   skip_build_kernel=0表示都是全新的节点,即假设所有节点(包括编译节点)都是没有安装Lustre对应内核;
skip_build_kernel=1

#只进行新节点虚拟机文件的复制 不进行后续工作
only_pre=0

#直接进入编译环节,不进行新节点虚拟机文件的复制
goto_compile=0

#是否进行lmt安装工作
install_lmt=1

while :;
do
    case $1 in
        --skip_build_kernel=?*)
            skip_build_kernel=${1#*=}
            shift
            ;;
        --goto_compile=?*)
            goto_compile=${1#*=}
            shift
            ;;
        --only_pre=?*)
            only_pre=${1#*=}
            shift
            ;;
        --install_lmt=?*)
            install_lmt=${1#*=}
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
#
#centos7.0-c1-centos7.0-c7是lustre文件系统测试节点,其中lustre适配的新内核已经安装完毕,如需要安装新内核,修改相关参数
#centosdev是编译lustre的节点,不是lustre文件系统的成员节点,相关的内核也安装完毕
#
print_message "MULTEXU_INFO" "Now start to prepare compiling files..."
#
#关闭旧机器 用新的备份节点替换文件 进行全新的安装
#
#yum install acpid -y
if [ ${goto_compile} -eq 0 ];then 

    if [ ${skip_build_kernel} -eq 0 ];then 
        virsh shutdown ${kvm_node_name_dev}
    fi
    for node_lustre in ${kvm_nodes_name_lustre[@]}
    do
        virsh shutdown ${node_lustre}
        `${PAUSE_CMD}`
    done
    sleep ${sleeptime}s

    print_message "MULTEXU_INFO" "Preparing new nodes..."
    #
    #复制备份节点  先关路径根据实际情况配置
    #
    for kvm_source in ${kvm_source_name_lustre[@]}
    do
        echo yes | cp ${kvm_source_bakpath}/${kvm_source} ${kvm_source_path}/${kvm_source}
        print_message "MULTEXU_INFO" "cp ${kvm_source_bakpath}/${kvm_source} ${kvm_source_path}/${kvm_source}..."
        wait
    done
    if [ ${skip_build_kernel} -eq 0 ];then 
        echo yes | cp ${kvm_source_bakpath}/${kvm_source_name_dev} ${kvm_source_path}/${kvm_source_name_dev}
        wait
    fi

    virsh start ${kvm_node_name_dev}
    `${PAUSE_CMD}`
    for node_lustre in ${kvm_nodes_name_lustre[@]}
    do
        virsh start ${node_lustre}
        `${PAUSE_CMD}`
    done
    
    #检测节点是否已经完成启动
    ping_check_singlenode_livestat ${compile_node_ip} "dead"  "${sleeptime}" "${limit}"
    ping_check_cluster_livestat "nodes_all.out" "dead" "${sleeptime}" "${limit}"
    print_message "MULTEXU_INFO" "New nodes are ready..."

`${PAUSE_CMD}`
`${PAUSE_CMD}`

fi

sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=nodes_all.out
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=nodes_all.out

if [ ${only_pre} -eq 1 ];then
    #计算程序运行的时间
    end_time=$(date +%s%N)
    end_time_ms=${end_time:0:16}
    #scale=6
    time_cost=0
    time_cost=`echo "scale=6;($end_time_ms - $start_time_ms)/1000000" | bc` 
    print_message "MULTEXU_INFO" "Total time spent:${time_cost} s"
    exit 0
fi

#删除旧文件
print_message "MULTEXU_INFO" "removing the old files..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="rm -rf ${base_dir}/Fdm-LustreQoS"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd='rm -rf /root/kernel/rpmbuild/BUILD/lustre-2.8.0/*'
rm -f ${MULTEXU_SOURCE_DIR}/install/lustre-*
`${PAUSE_CMD}`
`${PAUSE_CMD}`

#传送新文件到编译节点上
print_message "MULTEXU_INFO" "distributing the latest files..."
`${PAUSE_CMD}`
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --sendfile=${base_dir} --location="$( cd "${base_dir}" && cd ../ && pwd )"
sleep ${sleeptime}s

#编译&&安装内核
if [ ${skip_build_kernel} -eq 0 ];then     
    print_message "MULTEXU_INFO" "the nodes ${kvm_node_name_dev}:${current_node_ip} is going to build&&install new kernel..."   
    #
    #在编译节点上进行编译过程
    #编译lustre new kernel
    #清除信号量 避免干扰
    #
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_BUILD_DIR}/build_newkernel.sh"
    #kernel
    sleeptime=900
    ssh_check_singlenode_status ${compile_node_ip} "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
    sleeptime=60
    
    #处理安装之前的预操作 关闭SELinux 关闭防火墙等
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_INSTALL_DIR}/lustre_install_pre.sh"
    #检测上述操作是否完成
    ssh_check_singlenode_status ${compile_node_ip} "${MULTEXU_STATUS_EXECUTE}" $((sleeptime/4)) ${limit}

    #清除信号量  避免干扰
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
    `${PAUSE_CMD}`
    #置入重启之前信号量
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --send_execute_statu_signal=${MULTEXU_STATUS_REBOOT}"
    #命令结点重启
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --reboot
    print_message "MULTEXU_INFO" "the node ${kvm_node_name_dev}:${current_node_ip} is going to reboot..."
    #睡眠 暂停一段时间
    `${PAUSE_CMD}`
    #循环检测是否重启完成
    ssh_check_singlenode_status ${compile_node_ip} "${MULTEXU_STATUS_REBOOT}" ${sleeptime} ${limit}
    print_message "MULTEXU_INFO" "the node ${kvm_node_name_dev}:${current_node_ip} finished to reboot..."
    
    #检测和节点的状态：是否可达  ssh端口22是否启用
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=${compile_node_ip}
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=${compile_node_ip}
    
    #清除信号量  避免干扰
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
    #安装lustre新内核
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_INSTALL_DIR}/lustre_install_newkernel.sh"
    ssh_check_singlenode_status ${compile_node_ip} "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
    #清除信号量  避免干扰
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
    #置入重启之前信号量
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --send_execute_statu_signal=${MULTEXU_STATUS_REBOOT}"
    #命令结点重启
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --reboot
    print_message "MULTEXU_INFO" "the node ${kvm_node_name_dev}:${current_node_ip} is going to reboot..."
    #睡眠 暂停一段时间
    `${PAUSE_CMD}`
    `${PAUSE_CMD}`
    #循环检测是否重启完成
    ssh_check_singlenode_status ${compile_node_ip} "${MULTEXU_STATUS_REBOOT}" ${sleeptime} ${limit}
    print_message "MULTEXU_INFO" "the node ${kvm_node_name_dev}:${current_node_ip} finished to reboot..."
fi

#
#在编译节点上进行编译过程
#编译lustre server
#清除信号量 避免干扰
#
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_BUILD_DIR}/build_lustre_server.sh --skip_install_dependency=1"
#等待server编译完成
ssh_check_singlenode_status ${compile_node_ip} "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
print_message "MULTEXU_INFO" "the node ${compile_node_ip} finished to compile lustre-server..."


#复制编译生成的lustre server rpm包到指定目录
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="yes | cp /root/kernel/rpmbuild/BUILD/lustre-2.8.0/*.rpm ${MULTEXU_SOURCE_DIR}/install/ "
`${PAUSE_CMD}`
`${PAUSE_CMD}`

#编译lustre client
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="sh ${MULTEXU_BATCH_BUILD_DIR}/build_lustre_client.sh --skip_install_dependency=1"
#等待server编译完成
ssh_check_singlenode_status ${compile_node_ip} "${MULTEXU_STATUS_EXECUTE}" ${sleeptime} ${limit}
print_message "MULTEXU_INFO" "the node ${compile_node_ip} finished to compile lustre-client..."


#复制编译生成的lustre client rpm包到编译节点指定目录
print_message "MULTEXU_INFO" "Collecting files..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${compile_node_ip} --cmd="yes | cp /root/kernel/rpmbuild/BUILD/lustre-2.8.0/*.rpm ${MULTEXU_SOURCE_DIR}/install/ "
print_message "MULTEXU_INFO" "Finished to collect files..."
`${PAUSE_CMD}`
`${PAUSE_CMD}`

#从编译节点compile_node_ip复制编译好的lustre rpm包回到当前节点 也即控制节点
scp root@${compile_node_ip}:${MULTEXU_SOURCE_DIR}/install/* ${MULTEXU_SOURCE_DIR}/install/
sleep ${sleeptime}s

#分发文件到各个节点
print_message "MULTEXU_INFO" "Distributing files to all nodes..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --sendfile=${base_dir} --location="$( cd "${base_dir}" && cd ../ && pwd )"
sleep 180s
print_message "MULTEXU_INFO" "Finished to distribute files..."

sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal
#安装lustre文件系统  注意确定是否安装新内核
sh ${MULTEXU_BATCH_BUILD_DIR}/__config_lfz.sh #带宽限制配置文件
sh ${MULTEXU_BATCH_INSTALL_DIR}/auto_lustre2.8.0_install.sh --skip_install_kernel=${skip_build_kernel}
#等待安装完成
local_check_status "${MULTEXU_STATUS_EXECUTE}"  "${sleeptime}" "${limit}"
print_message "MULTEXU_INFO" "the current node finished to execute auto_lustre2.8.0_install.sh..."

#设置printk级别 清除无用日志信息 方便输出调试信息
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd='echo 8 > /proc/sys/kernel/printk'
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd='dmesg --clear'

#部署文件系统
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal
sh ${MULTEXU_BATCH_DEPLOY_DIR}/auto_lustre2.8.0_deploy.sh --mdsnode=${mdsnode} --devname=${devname} --devindex=${devindex}
#等待部署完成
while [[ $(cat ${EXECUTE_STATUS_SIGNAL}) != "${MULTEXU_STATUS_EXECUTE}" ]];
	do
		print_message "MULTEXU_INFO" "the current node is executing auto_lustre2.8.0_deploy.sh..."
		sleep ${sleeptime}s
done
print_message "MULTEXU_INFO" "the current node finished to execute auto_lustre2.8.0_deploy.sh..."

sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal

#安装lmt
if [ ${install_lmt} -eq 1 ];then
    sh ${MULTEXU_BATCH_LMT_DIR}/lmt_install.sh --mdsnode=${mdsnode}
    local_check_status "${MULTEXU_STATUS_EXECUTE}"  "${sleeptime}" "${limit}"
    print_message "MULTEXU_INFO" "the current node  finished to execute lmt_install.sh..."

    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal
fi

#计算程序运行的时间
end_time=$(date +%s%N)
end_time_ms=${end_time:0:16}
#scale=6
time_cost=0
time_cost=`echo "scale=6;($end_time_ms - $start_time_ms)/1000000" | bc` 
print_message "MULTEXU_INFO" "Process compile-->install-->deploy lustre 2.8.0 finished..."
print_message "MULTEXU_INFO" "Total time spent:${time_cost} s"
