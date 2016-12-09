#!/bin/bash
# POSIX
#
#description:    uninstall lustre new kernel
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-11-02
#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
    echo "MULTEXU Error:multexu initialization failure:cannot find the file __init.sh... "
    exit 1
else
    source ../ctrl/__init.sh
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"                                                                     
clear_execute_statu_signal

print_message "MULTEXU_INFO" "now start uninstall lustre new kernel..."
yum remove kernel-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64-1.x86_64
wait
rpm -e kernel-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64-1.x86_64
wait

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
`${PAUSE_CMD}`
exit 0

