#!/bin/bash
# POSIX
#
#description:    add and patch files for metric
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-10-12
#

#
#这里暂时不要使用信号量，因为管理节点一直在周期性检测执行结果状态了会与管理节点的信号量冲突，
#会发生信号量冲突。后续版本若确实需要使用信号量，可以考虑重新定义规范的信号量体系来解决该问题
#

#
#当前为方便开发，补丁操作直接采取替换文件的方式。
#在正式发布稳定版本时，可以使用diff命令生成的补丁文件，进行规范的补丁操作
#

#lustre/
cp -rf ${MULTEXU_SOURCE_BUILD_DIR}/metric/metric-tests lustre/
#lustre/osc/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/osc_request.c lustre/osc/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lproc_osc.c lustre/osc/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/osc_cache.c lustre/osc/
cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/qos_rules.c lustre/osc/

#lustre/include/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/obd.h lustre/include/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lprocfs_status.h lustre/include/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lustre_nrs_tbf.h lustre/include/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lustre_net.h lustre/include/
cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/metric.h lustre/include/

#lustre/include/lustre/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lustre_idl.h lustre/include/lustre/

#lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/pack_generic.c lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/nrs_tbf.c lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lproc_ptlrpc.c lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/service.c lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lustre_ptlrpc_wiretest.c lustre/ptlrpc/wiretest.c

#lustre/obdclass/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/genops.c lustre/obdclass/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lprocfs_status.c lustre/obdclass/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/lprocfs_counters.c lustre/obdclass/

#lustre/utils/
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/tgt_handler.c lustre/target/

#lustre/target/

#Makefile文件
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/Makefile/lustre_include_Makefile.am lustre/include/Makefile.am
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/Makefile/lustre_include_Makefile.in lustre/include/Makefile.in
yes | cp ${MULTEXU_SOURCE_BUILD_DIR}/metric/Makefile/lustre_osc_Makefile.in lustre/osc/Makefile.in


