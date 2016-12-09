#!/bin/bash
# POSIX
#
#description:    parted a dev automatically
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-25
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

devname= #设备名称
devindex= #分区索引号
#分区起始位置
start= 

while getopts 'd:i:' opt;do
	case $opt in
		d)
			devname=$OPTARG;;
		i)
			devindex=$OPTARG;;
	esac
done
if [ ! -n ${devname} ] || [ ! -n ${devindex} ]; then
    print_message "MULTEXU_ERROR" "-d|-i is necessary..."
    exit 1
fi
start=`parted ${devname} print free |awk '$0 ~ /Free Space/ {print $1}' | tail -1` #分区索引号

if [ ! -n "${start}" ]; then
    start="0G"
fi
#获取本机ip 并安装一定格式处理
ip=`ifconfig | grep "inet addr:" | grep -v "127.0.0.1" | cut -d: -f2|awk '{print $1}'`

#格式化为主分区还是逻辑分区,默认是逻辑分区
type_of_partition="logical"
if [[ devindex -le 4 ]];then
    type_of_partition="primary"    
fi
parted -s ${devname} mkpart ${type_of_partition} ${start} 100%
print_message "MULTEXU_INFO" "node[${ip}]: parted -s ${devname} mkpart ${type_of_partition} ${start} 100% ..."

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
