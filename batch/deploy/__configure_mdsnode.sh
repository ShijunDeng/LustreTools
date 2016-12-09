#!/bin/bash
# POSIX
#
#description:    configure mgsnode automatically
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

#设备名称
devname=
#lustre 的index
index=
#挂载位置
mnt_position=

#
#获取参数
#
while getopts 'd:i:m:' opt;do
	case $opt in
		d)
			devname=$OPTARG;;
		i)
			index=$OPTARG;;
		m)
			mnt_position=$OPTARG;;
	esac
done

if [ ! -n ${devname} ] || [ ! -n ${index} ] || [ ! -n ${mnt_position} ]; then
	print_message "MULTEXU_ERROR" "-d|-i|-m is necessary..."
	exit 1
fi

#
#格式化lustre文件系统
#
mkfs.lustre --fsname=lustrefs --mgs --mdt --index=$index $devname
wait


if [ ! -d "/mnt/${mnt_position}" ]; then
    mkdir /mnt/${mnt_position}
fi

mount -t lustre ${devname} /mnt/$mnt_position
wait
modprobe lustre
wait

#设置完成标识
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"

exit 0
