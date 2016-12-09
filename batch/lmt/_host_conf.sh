#!/bin/bash
# POSIX
#
#description:    configure /etc/host && /etc/hostfile
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-10-19
#
#initialization
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
#hostfile="/etc/hostfile"

#配置/etc/hosts
#cat ${MULTEXU_BATCH_CONFIG_DIR}/hosts | while read hosts_line; 
#do 
#	echo "${hosts_line}" >> /etc/hosts
#done
yes | cp ${MULTEXU_BATCH_CONFIG_DIR}/hosts /etc/

#配置/etc/hostfile
#if [ ! -f "${hostfile}" ]; then
            #touch ${hostfile}
#fi

#cat ${MULTEXU_BATCH_CONFIG_DIR}/hostfile | while read hostfile_line; 
#do 
#	echo ${hostfile_line} >> ${hostfile}
#done
yes | cp ${MULTEXU_BATCH_CONFIG_DIR}/hostsfile /etc/
#设置完成标识
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
`${PAUSE_CMD}`
