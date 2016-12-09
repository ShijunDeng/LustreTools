#!/bin/bash
# POSIX
#
#description:    install cerebro automaticlly
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-10-19
#
#initialization

sleeptime=60 #设置检测的睡眠时间
limit=10 #递减下限

cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
	echo "MULTEXU Error:initialization failure:cannot find the file __init.sh... "
	exit 1
else
	source ../ctrl/__init.sh
	echo 'MULTEXU INFO:initialization completed...'
	`${PAUSE_CMD}`
fi
source "${MULTEXU_BATCH_CRTL_DIR}"/multexu_lib.sh #调入multexu库
clear_execute_statu_signal

cd "${MULTEXU_SOURCE_DIR}"/lmt
print_message "MULTEXU_INFO" "enter directory ${MULTEXU_SOURCE_DIR}/lmt..."
print_message "MULTEXU_INFO" "install dependencies..."    
#lustre-modules-2.8.0-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64.x86_64 has missing requires of kernel = ('0', '3.10.0', '3.10.0-327.3.1.el7_lustre')
#yum clean all &&yum update glibc glibc-headers glibc-devel nscd && yum update
yum -y install libtool-ltdl-devel glibc-common libtool autoconf automake mysql-devel expat-devel openssl098e perl-Date-Manip
wait
sleep ${sleeptime}s

rpm -ivh cerebro-1.12-1.x86_64.rpm
wait
rpm -ivh cerebro-clusterlist-hostsfile-1.12-1.x86_64.rpm
wait
rpm -ivh cerebro-metric-boottime-1.12-1.x86_64.rpm
wait
rpm -ivh cerebro-metric-loadavg-1.12-1.x86_64.rpm
wait
rpm -ivh cerebro-metric-memory-1.12-1.x86_64.rpm
wait
rpm -ivh cerebro-metric-network-1.12-1.x86_64.rpm
wait
rpm -ivh cerebro-event-updown-1.12-1.x86_64.rpm
wait

#设置完成标识
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "leave directory $( dirname "${BASH_SOURCE[0]}" )..."

`${PAUSE_CMD}`
