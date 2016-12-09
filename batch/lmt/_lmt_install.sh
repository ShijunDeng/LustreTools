#!/bin/bash
# POSIX
#
#description:    install Lustre Monitoring Tool server && server agent(lmt-server-agent)automaticlly
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-10-19
#
#initialization
sleeptime=60 #设置检测的睡眠时间
limit=10 #递减下限
#安装server/server-agent
option=$1

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
yum -y install libtool-ltdl-devel glibc-common libtool autoconf automake mysql-devel expat-devel install openssl098e install perl-Date-Manip
wait
sleep ${sleeptime}s

if [[ "${option}" == "--server" ]];then
	rpm -ivh lmt-server-3.1.2-1.x86_64.rpm
elif [[ "${option}" == "--server-agent" ]];then
	rpm -ivh lmt-server-agent-3.1.2-1.x86_64.rpm   
else
	print_message "MULTEXU_ERROR" "unknown option:${option}"
	exit 1
fi
`${PAUSE_CMD}`

#设置完成标识
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "leave directory $( dirname "${BASH_SOURCE[0]}" )..."

`${PAUSE_CMD}`
