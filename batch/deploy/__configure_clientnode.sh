#!/bin/bash
# POSIX
#
#description:    configure client node automatically
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

client_mnt_dir=
mdsnode=

while getopts 's:m:' opt;
do
    case $opt in
        s)
                mdsnode=$OPTARG;;
        m)
                client_mnt_dir=$OPTARG;;
    esac
done

auto_mkdir "${client_mnt_dir}" "weak" 

print_message "MULTEXU_INFO" "client [${ip}] mount -t lustre ${mdsnode}@tcp:/lustrefs ${client_mnt_dir}"
mount -t lustre ${mdsnode}@tcp:/lustrefs ${client_mnt_dir}
wait

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
exit 0

