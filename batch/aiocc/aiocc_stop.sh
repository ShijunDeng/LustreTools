#!/bin/sh
#POSIX
#

#description:    stop distributed filesystem automatic I/O congestion control
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2017-01-03
#
#运行本脚本时,假设主控制节点与所有节点(包括编译节点)已经进行SSH认证
#

#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f __aiocc_init.sh ]; then
	echo "AIOCC Error:initialization failure:cannot find the file __aiocc_init.sh... "
	exit 1
else
	source ../__aiocc_init.sh
	echo 'AIOCC INFO:initialization completed...'
	`${PAUSE_CMD}`
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"
clear_execute_statu_signal 

echo "false" > ${AIOCC_CONFIG_DIR}/work_loop.cfg
print_message "MULTEXU_INFO" "AIOCC has been stopped..."