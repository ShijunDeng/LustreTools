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
source "${MULTEXU_BATCH_CRTL_DIR}"/multexu_lib.sh #调入multexu库

#MULTEXU_STATUS_REBOOT="REBOOT" #重启状态过程
#MULTEXU_STATUS_EXECUTE="EXECUTE" #执行过程

#
#测试给定主机是否可达
#参数：ip
#
function __test_host_available()
{
    local host_ip=$1
    ping -c1 -w1 $host_ip &>/dev/null
    if [ $? -ne 0 ] 
    then
        print_message "MULTEXU_ERROR" "destination host[${host_ip}] unreachable..."
    else
        print_message "MULTEXU_INFO" "destination host[${host_ip}] reachable..."
    fi
}

#
#测试给定主机是否可达
#参数192.168.3.110,192.168.3.122  or xxx.out
#

function test_host_available()
{
    if [[ $1 =~ ".out" ]]; then #参数以xxx.out文件形式给出
        for host_ip in $(cat "$MULTEXU_BATCH_CONFIG_DIR"/"$1")
        do
            __test_host_available "${host_ip}"
        done
    
    else #参数以逗号隔开形式给出
        local iptable_var=`echo $@ | sed s/[[:space:]]//g`
        OLD_IFS="$IFS" 
        IFS=","
        local ip_array=($iptable_var)
        IFS="$OLD_IFS" 
        
        for host_ip in ${ip_array[@]} 
        do
            __test_host_available "${host_ip}"
        done
    fi

}


#
#测试给定主机是否可达
#参数：ip
#
function __test_host_ssh_enabled()
{
    local host_ip=$1
    (nc ${host_ip}  22  < /dev/null) &> /dev/null
    if [ $? -eq 0 ]; then
        print_message "MULTEXU_INFO" "ssh is enabled on the remote computer[${host_ip}]..."
    else
        print_message "MULTEXU_ERROR" "ssh is not enabled on the remote computer[${host_ip}]..."
    fi
}

#
#测试给定主机是否可达
#参数192.168.3.110,192.168.3.122  or xxx.out
#

function test_host_ssh_enabled()
{
    if [[ $1 =~ ".out" ]]; then #参数以xxx.out文件形式给出
        for host_ip in $(cat "$MULTEXU_BATCH_CONFIG_DIR"/"$1")
        do
            __test_host_ssh_enabled "${host_ip}"
        done
    
    else #参数以逗号隔开形式给出
        local iptable_var=`echo $@ | sed s/[[:space:]]//g`
        OLD_IFS="$IFS" 
        IFS=","
        local ip_array=($iptable_var)
        IFS="$OLD_IFS" 
        
        for host_ip in ${ip_array[@]} 
        do
            __test_host_ssh_enabled "${host_ip}"
        done
    fi

}

function get_parameters()
{
    local parameter_name=$1
    local parameter_value=${1#*=}
    
    case "${parameter_name}" in
        --send_execute_statu_signal=?*)
            send_execute_statu_signal "${parameter_value}"
            ;;
        --clear_execute_statu_signal)
            clear_execute_statu_signal
            ;;
        --test_host_available=?*)
            test_host_available "${parameter_value}"
            ;;
        --test_host_ssh_enabled=?*)
            test_host_ssh_enabled "${parameter_value}"
            ;;
        *)
            exit 1
            ;;
    esac
} 

get_parameters $@
