#!/bin/bash
# POSIX
#
#description:    configure ossnode automatically
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
#
#信号量交给__configure_ossnode.sh完成
#
#ost 的index
index=0

#设备名称
devname=
#挂载位置
mnt_position=
#mdsnode的位置
mdsnode=

#
#获取参数
#
while getopts 'd:s:m:' opt;do
    case $opt in
        d)
            devname=$OPTARG
            ;;
        m)
            mnt_position=$OPTARG
            ;;
        s)
            mdsnode=$OPTARG
            ;;
    esac
done


if [ ! -n ${mdsnode} ] || [ ! -n ${devname} ]  || [ ! -n ${mnt_position} ]; then
    print_message "MULTEXU_ERROR" "-s|-d|-m is necessary..."
    exit 1
fi

for host_ip in $(cat ${MULTEXU_BATCH_CONFIG_DIR}/nodes_oss.out)
do
    command_var="sh ${MULTEXU_BATCH_DEPLOY_DIR}/__configure_ossnode.sh -i ${index} -s ${mdsnode} -d ${devname} -m ${mnt_position}"
    print_message "MULTEXU_INFO" "${host_ip}:${command_var}..."
    ssh -f ${host_ip} "${command_var}"
    let index++
done
