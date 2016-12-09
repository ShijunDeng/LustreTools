#!/bin/bash
# POSIX
#
#description:    configure mdsnode automatically
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
#ost 的index
index=
#挂载位置
mnt_position=
#mdsnode的ip地址
mdsnode=

while getopts 's:d:i:m:' opt;
do
    case $opt in
    s)
        mdsnode=$OPTARG;;
    d)
        devname=$OPTARG;;
    i)
        index=$OPTARG;;
    m)
        mnt_position=$OPTARG;;
    esac
done
if [ ! -n ${mdsnode} ] || [ ! -n ${devname} ] || [ ! -n ${index} ] || [ ! -n ${mnt_position} ]; then
    print_message "MULTEXU_ERROR" "-s|-d|-i|-m is necessary..."
    exit 1
fi
#
#若给出的mnt_position为ost index 为0 ，则实际上挂载点设置mnt_position为ost0
#
mnt_position="${mnt_position}${index}"
ip=`ifconfig|grep "inet addr:"|grep -v "127.0.0.1"|cut -d: -f2|awk '{print $1}'`
`${PAUSE_CMD}`

#
#这里注意参数的名字一致 mdsnode=mdsnode
#
mkfs.lustre --fsname=lustrefs --mgsnode=$mdsnode@tcp --ost --index=$index $devname
wait

if [ ! -d "/mnt/${mnt_position}" ]; then
    mkdir "/mnt/${mnt_position}"
fi

mount -t lustre ${devname} "/mnt/${mnt_position}"
wait
modprobe lustre
wait

#设置完成标识
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"

exit 0
