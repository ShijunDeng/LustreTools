#!/bin/bash
# POSIX
#
#description:    uninstall lustre client
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

source "${MULTEXU_BATCH_CRTL_DIR}"/multexu_lib.sh #调入multexu库
clear_execute_statu_signal  
                                                              
print_message "MULTEXU_INFO" "now start uninstall lustre client..."

rpm -e lustre-modules
wait
rpm -e lustre-client
wait
rpm -e lustre-client-modules
wait

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
