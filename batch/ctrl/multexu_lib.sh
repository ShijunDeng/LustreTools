#!/bin/bash
# POSIX
#
#description:    the base library for mutlexu
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-24

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
#
function send_execute_statu_signal()
{
    local signal_content=$1
    if [ ! -f "${EXECUTE_STATUS_SIGNAL}" ]; then
        touch "${EXECUTE_STATUS_SIGNAL}"
    fi
    echo "${signal_content}" > "${EXECUTE_STATUS_SIGNAL}"
}

#
#清空通信文件中的信号变量
#
function clear_execute_statu_signal()
{
    if [ ! -f "${EXECUTE_STATUS_SIGNAL}" ]; then
	    touch "${EXECUTE_STATUS_SIGNAL}"
    fi
        echo "" > "${EXECUTE_STATUS_SIGNAL}"	
}

#
#获得$1指定节点的状态变量
#
function ssh_get_execute_statu_signal()
{
    local rs=
    local ip=$1
        rs=`ssh -f ${ip} "cat ${EXECUTE_STATUS_SIGNAL}"`
    eval "$2=$rs"
}

#
#检测本地节点的状态：$(cat ${EXECUTE_STATUS_SIGNAL}) 
#参数顺序:status sleeptime limit
#
function local_check_status()
{
        local loop=1
        local status=$1
        local sleeptime=$2
        local limit=$3
        while [[ loop -ne 0 ]]
        do
            loop=0;
            print_message "MULTEXU_INFO" "the state of local node:[${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            local retval=$(cat ${EXECUTE_STATUS_SIGNAL}) 
            if [[ "${retval}" != "${status}" ]]
            then
                    loop=1
            fi
            if [[ sleeptime -gt limit ]]
            then
                let sleeptime/=2
            fi
        done
}

#
#检测单个节点的状态
#参数顺序:hostip status sleeptime limit
#
function ssh_check_singlenode_status()
{
        local loop=1
        local host_ip=$1
        local status=$2
        local sleeptime=$3
        local limit=$4
        while [[ loop -ne 0 ]]
        do
            loop=0;
            print_message "MULTEXU_INFO" "the state of node ${host_ip}:[${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            local retval=
            ssh_get_execute_statu_signal "${host_ip}" retval
            #retval=$?
            if [[ "${retval}" != "${status}" ]]
            then
                    loop=1
            fi
            if [[ sleeptime -gt limit ]]
            then
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
        local loop=1
        local iptable=$1
        local status=$2
        local sleeptime=$3
        local limit=$4

        while [[ loop -ne 0 ]]
        do
            loop=0;
            print_message "MULTEXU_INFO" "the state of nodes which its ip in ${iptable}:[ ${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            for host_ip in $(cat  "${MULTEXU_BATCH_CONFIG_DIR}/${iptable}")
            do
                local retval=
                ssh_get_execute_statu_signal "${host_ip}" retval
                #retval=$?
                if [[ "${retval}" != "${status}" ]]
                then
                    loop=1
                    break
                 fi
            done
            if [[ sleeptime -gt limit ]]
            then
                let sleeptime/=2;
            fi
        done
}

#
#使用ping命令检测$1指定的节点生存状态,位置参数2返回结果
#return：0 dead
#        1 alive
#
function ping_get_node_livestat()
{
    if ping -c 1 -w 5 $1 &> /dev/null
    then
        eval "$2=1"
    else
        eval "$2=0"
    fi
    
}
#
#ping检测单个节点的状态,直到节点启动
#参数顺序:hostip status sleeptime limit
#
function ping_check_singlenode_livestat()
{
        local loop=1
        local host_ip=$1
        local status=$2
        local sleeptime=$3
        local limit=$4
        while [[ loop -ne 0 ]]
        do
            loop=0;
            print_message "MULTEXU_INFO" "the state of node ${host_ip}:[${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            local retval=
            ping_get_node_livestat "${host_ip}" retval
            #retval=$?
            if [[ retval -ne 1 ]]
            then
                    loop=1
            fi
            if [[ sleeptime -gt limit ]]
            then
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
        local loop=1
        local iptable=$1
        local status=$2
        local sleeptime=$3
        local limit=$4

        while [[ loop -ne 0 ]]
        do
            loop=0;
            print_message "MULTEXU_INFO" "the state of nodes which its ip in ${iptable}:[${status}],the next check time will be ${sleeptime}s later..."
            sleep ${sleeptime}s
            for host_ip in $(cat  "${MULTEXU_BATCH_CONFIG_DIR}/${iptable}")
            do
                local retval=
                ping_get_node_livestat "${host_ip}" retval
                #retval=$?
                if [[ retval -ne 1 ]]
                then
                    loop=1
                    break
                fi
            done
            if [[ sleeptime -gt limit ]]
            then
                let sleeptime/=2;
            fi
        done
}



#
#输出程序的提示信息
#参数：消息类型  消息内容
#MULTEXU_INFO 普通信息
#MULTEXU_ERROR 错误
#MULTEXU_WARN 警告信息
#MULTEXU_ECHO 输出不带标志,直接封装echo,和echo效果一样
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
    esac
}

