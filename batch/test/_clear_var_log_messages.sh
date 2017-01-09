#!/bin/bash
# POSIX
#
#description:    clear logs
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-19
#
#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
    echo "MULTEXU Error:multexu initialization failure:cannot find the file __init.sh... "
    exit 1
else
    source ../ctrl/__init.sh
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"  

VAR_LOG_DIR="/var/log"
if [ ! -f ${MULTEXU_BATCH_TEST_DIR}/_clear_var_log_messages.cfg ];then
	echo "false" > ${MULTEXU_BATCH_TEST_DIR}/_clear_var_log_messages.cfg
fi

START_SIGNAL="cat  ${MULTEXU_BATCH_TEST_DIR}/_clear_var_log_messages.cfg"
if [ x`$START_SIGNAL` = x"true" ];then
	print_message "MULTEXU_INFO" "_clear_var_log_messages.sh is runing,no need to run it again..."
	exit 0
fi
echo "true" >  ${MULTEXU_BATCH_TEST_DIR}/_clear_var_log_messages.cfg
while [ x`$START_SIGNAL` = x"true" ]
do
    :>${VAR_LOG_DIR}/messages
    sleep 3600s
done

