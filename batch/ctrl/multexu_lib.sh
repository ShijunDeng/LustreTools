#!/bin/bash
# POSIX
#
#description:    the base library for mutlexu
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-24
#last revise:	 2017-01-13

#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f __init.sh ]; then
    echo "MULTEXU ERROR:multexu initialization failure:cannot find the file __init.sh... "
    exit 1
else
    source ./__init.sh
fi

#MULTEXU_STATUS_REBOOT="REBOOT" #重启状态过程
#MULTEXU_STATUS_EXECUTE="EXECUTE" #执行过程

#
#往通信文件中写入一个信号变量
#$1 signal content
#$2 signal file name,默认值"${EXECUTE_STATUS_SIGNAL}"
#
function send_execute_statu_signal()
{
	if [ -n "$2" ];then
		echo "$1" > "$2"
	else
		send_execute_statu_signal $1 "${EXECUTE_STATUS_SIGNAL}"
	fi
}

#
#清空通信文件中的信号变量
#$1 信号量文件,默认值"${EXECUTE_STATUS_SIGNAL}"
#
function clear_execute_statu_signal()
{
    if [ -n "$1" ];then
		: > "$1"
	else
		clear_execute_statu_signal "${EXECUTE_STATUS_SIGNAL}"
	fi	
}

#
#获得指定节点的状态变量
#$2指定节点的ip
#$3信号量文件 缺省的情况默认信号量文件为$EXECUTE_STATUS_SIGNAL
#
function ssh_get_execute_statu_signal()
{
    local ip=$2
	local signal_file=$3
	if [ ! -f "${signal_file}" ];then
		signal_file=${EXECUTE_STATUS_SIGNAL}
	fi
    local rs=`ssh -f ${ip} "cat ${signal_file}"`
    eval "$1=$rs"
}

#
#检测本地节点的状态：$(cat ${EXECUTE_STATUS_SIGNAL}) 
#参数顺序:status sleeptime limit
#
function local_check_status()
{
        local status=$1
        local sleeptime=$2
        local limit=$3
		local signal_file=$4
		if [ ! -f "${signal_file}" ];then
			signal_file=${EXECUTE_STATUS_SIGNAL}
		fi
        while [ true ]
        do
            print_message "MULTEXU_INFO" "waiting for local node signal:[${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            local retval=$(cat ${signal_file}) 
            if [ "${retval}" = "${status}" ];then
                break
            fi
            if [ $sleeptime -gt $limit ];then
                let sleeptime/=2
            fi
        done
}

#
#检测单个节点的状态
#参数顺序:hostip status sleeptime limit signal_file
#signal_file:信号量文件,默认值"${EXECUTE_STATUS_SIGNAL}"
function ssh_check_singlenode_status()
{
        local host_ip=$1
        local status=$2
        local sleeptime=$3
        local limit=$4
		local signal_file=$5
        while [ true ];
        do
            print_message "MULTEXU_INFO" "waiting for node ${host_ip} signal:[${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            local retval=
			ssh_get_execute_statu_signal retval "${host_ip}" "${signal_file}" 
            #retval=$?
            if [ "${retval}" = "${status}" ];then
                break
            fi
            if [ $sleeptime -gt $limit ];then
                let sleeptime/=2
            fi
        done
}

#
#检测集群节点的状态
#参数顺序:iptable status sleeptime limit
#
function ssh_check_cluster_status()
{
        local iptable=$1
        local status=$2
        local sleeptime=$3
        local limit=$4
		local signal_file=$5
		
        while [ true ];
        do
            print_message "MULTEXU_INFO" "waiting for nodes which its ip in ${iptable} signal [${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            for host_ip in $(cat "${MULTEXU_BATCH_CONFIG_DIR}/${iptable}")
            do
                local retval=
                ssh_get_execute_statu_signal retval "${host_ip}" "${signal_file}" 
                #retval=$?
                if [ "${retval}" = "${status}" ];then
                    break 2
                fi
            done
            if [ $sleeptime -gt $limit ];then
                let sleeptime/=2
            fi
        done
}

#
#使用ping命令检测$2指定的节点生存状态,位置参数1返回结果
#return：1 dead
#        0 alive
#
function ping_get_node_livestat()
{
    if [ ping -c 1 -w 5 $2 &> /dev/null ];then
        eval "$1=0"
    else
        eval "$1=1"
    fi
    
}
#
#ping检测单个节点的状态,直到节点启动
#参数顺序:hostip status sleeptime limit
#
function ping_check_singlenode_livestat()
{
        local host_ip=$1
        local status=$2
        local sleeptime=$3
        local limit=$4
        while [ loop -ne 0 ]
        do
            print_message "MULTEXU_INFO" "ping check node ${iptable} live state,waiting for the signal [${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            local retval=
            ping_get_node_livestat retval "${host_ip}" 
            #retval=$?
            if [ $retval ];then
				break
            fi
            if [ $sleeptime -gt $limit ];then
                let sleeptime/=2
            fi
        done
}

#
#ping检测集群节点的状态,直到节点启动
#参数顺序:iptable status sleeptime limit
#
function ping_check_cluster_livestat()
{
        local iptable=$1
        local status=$2
        local sleeptime=$3
        local limit=$4
        while [ true ];
        do
            print_message "MULTEXU_INFO" "ping check cluster ${iptable} live state,waiting for the signal [${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            for host_ip in $(cat "${MULTEXU_BATCH_CONFIG_DIR}/${iptable}")
            do
                local retval=
                ping_get_node_livestat retval "${host_ip}"
                #retval=$?
                if [ $retval ];then
                    break 2
                fi
            done
            if [ $sleeptime -gt $limit ];then
                let sleeptime/=2
            fi
        done
}

#
#根据$2选项参数,自动创建$1参数指定的目录(一律使用mkdir -p):
#关于$2选项说明:
#	--force 创建$1目录之前先检测$1是否存在:若存在,先删除旧目录后创建;否则直接创建新目录$1
#	--weak  创建$1目录之前先检测$1是否存在:若存在不执行创建操作;否则创建新目录$1
#	$2若未明确给出,默认为weak
#
function auto_mkdir()
{
	#$1 dirname $2 option
	if [ $# -lt 1 ];then
		return
	fi
	if [ $# -eq 1 -o "$2"x == "weak"x ];then
		if [ ! -d $1 ];then
			mkdir -p $1
			return
		fi
	fi
	if [ $# -eq 2 -a "$2"x == "force"x ];then
		if [ -d $1 ];then
			rm -rf $1
		fi
		auto_mkdir $1 "weak"
	fi	
}

#
#输出程序的提示信息
#参数：消息类型  消息内容
#MULTEXU_INFO 普通信息
#MULTEXU_ERROR 错误
#MULTEXU_WARN 警告信息
#MULTEXU_ECHO 输出不带标志,直接封装echo,和echo效果一样
#MULTEXU_ECHOX 在输入以前先执行一条命令(主要是重定向之类的命令)
#
function print_message()
{
    local message_type=$1
    shift
    case ${message_type} in
        MULTEXU_INFO|MULTEXU_ERROR|MULTEXU_WARN)
            echo "${message_type}:$@"
            ;;
        MULTEXU_ECHO)
            echo "$@"
           ;;
		MULTEXU_ECHOX)
			local cmd=$1
			shift
            if [ "x${cmd}" = "x1>&2" -o "x${cmd}" = "x1&>2" -o "x${cmd}" = "x&>2" -o "x${cmd}" = "x>&2" ];then
                1>&2 echo "$@"
            fi            
    esac
}

