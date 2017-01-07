#!/bin/sh
#POSIX
#

#description:    define configuration variables
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-12-31
#
#运行本脚本时,假设主控制节点与所有节点(包括编译节点)已经进行SSH认证
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

#
#	分布式文件系统自动I/O拥塞控制
#	distributed filesystem automatic I/O congestion control
#	AIOCC
#
#__aiocc_init()
#
export AIOCC_BATCH_DIR="${MULTEXU_BATCH_DIR}/aiocc"
export AIOCC_SOURCE_DIR="${MULTEXU_SOURCE_DIR}/aiocc"
export AIOCC_SEARCH_POLICY_DIR="${AIOCC_BATCH_DIR}/search_policy"
export AIOCC_CONFIG_DIR="${AIOCC_BATCH_DIR}/config"
export AIOCC_RULE_DIR="${AIOCC_SOURCE_DIR}/rule"

export AIOCC_CTROL_STATUS_CONTINUE="CONTINUE" 
export AIOCC_CTROL_STATUS_EXIT="EXIT" 
export AIOCC_EXECUTE_STATUS_FINISHED="FINISHED"

#执行过程中的信号处理,存储信号的共享文件
export AIOCC_EXECUTE_SIGNAL_FILE="${AIOCC_CONFIG_DIR}/execute.signal" 
export AIOCC_CTROL_SIGNAL_FILE="${AIOCC_CONFIG_DIR}/control.signal" 


