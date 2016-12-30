#!/bin/sh
# POSIX
#
#description:    define configuration variables
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#	time:    2016-07-19
#

#
#MULTEXU环境变量初始化,注意__multexu_init应该最先调用
#
function __multexu_init()
{
	export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
	export LANG="en_US.UTF-8"

	export MULTEXU_BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../ && pwd )"
	export MULTEXU_SOURCE_DIR="${MULTEXU_BASE_DIR}/source"
	export MULTEXU_BATCH_DIR="${MULTEXU_BASE_DIR}/batch"
	export MULTEXU_CODE_DIR="${MULTEXU_BASE_DIR}/code"

	export MULTEXU_BATCH_AUTHORIZE_DIR="${MULTEXU_BATCH_DIR}/authorize"
	export MULTEXU_BATCH_BUILD_DIR="${MULTEXU_BATCH_DIR}/build"
	export MULTEXU_BATCH_CONFIG_DIR="${MULTEXU_BATCH_DIR}/config"
	export MULTEXU_BATCH_CRTL_DIR="${MULTEXU_BATCH_DIR}/ctrl"
	export MULTEXU_BATCH_DEPLOY_DIR="${MULTEXU_BATCH_DIR}/deploy"
	export MULTEXU_BATCH_INSTALL_DIR="${MULTEXU_BATCH_DIR}/install"
    export MULTEXU_BATCH_UNINSTALL_DIR="${MULTEXU_BATCH_DIR}/uninstall"
	export MULTEXU_BATCH_LMT_DIR="${MULTEXU_BATCH_DIR}/lmt"
	export MULTEXU_BATCH_TEST_DIR="${MULTEXU_BATCH_DIR}/test"
	
	export MULTEXU_SOURCE_BUILD_DIR="${MULTEXU_SOURCE_DIR}/build"
	export MULTEXU_SOURCE_INSTALL_DIR="${MULTEXU_SOURCE_DIR}/install"
	export MULTEXU_SOURCE_LMT_DIR="${MULTEXU_SOURCE_DIR}/lmt"
	export MULTEXU_SOURCE_TOOL_DIR="${MULTEXU_SOURCE_DIR}/tool"
	
	export PAUSE_CMD="sleep 3s"
	
	#重启状态过程
	export MULTEXU_STATUS_REBOOT="REBOOT" 
	#执行过程
	export MULTEXU_STATUS_EXECUTE="EXECUTE" 
	
	#执行过程中的信号处理,存储信号的共享文件
	export EXECUTE_STATUS_SIGNAL="${MULTEXU_BATCH_CONFIG_DIR}/multexu.tmp" 
}

#
#	分布式文件系统自动I/O拥塞控制
#	distributed filesystem automatic I/O congestion control
#	AIOCC
#
function __aiocc_init()
{			
	export AIOCC_BASE_DIR="${MULTEXU_BASE_DIR}/aiocc"
	export AIOCC_RULE_DIR="${AIOCC_BASE_DIR}/rule"
	export AIOCC_RULE_CANDIDATE_DIR="${AIOCC_RULE_DIR}/candidate"
	export AIOCC_RULE_DATABASE_DIR="${AIOCC_RULE_DIR}/database" 
}

#
#调用所有的初始化操作
#
function __init()
{
	#调用MULTEXU系统初始化
	__multexu_init
	__aiocc_init
}

##################
__init

