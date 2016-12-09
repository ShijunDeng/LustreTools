#!/bin/sh
# POSIX
#
#description:    define configuration variables
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#	time:    2016-07-19
#
function __init()
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
	
	export PAUSE_CMD="sleep 3s"

	export MULTEXU_STATUS_REBOOT="REBOOT" #重启状态过程
	export MULTEXU_STATUS_EXECUTE="EXECUTE" #执行过程
	
	export EXECUTE_STATUS_SIGNAL="${MULTEXU_BATCH_CONFIG_DIR}/multexu.tmp" #执行过程中的信号处理
}

##################

__init
