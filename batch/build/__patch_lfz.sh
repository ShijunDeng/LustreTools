#!/bin/bash
# POSIX
#
#description:    add and patch files for bandwidth throttling
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-12-13
#

#
#这里暂时不要使用信号量，因为管理节点一直在周期性检测执行结果状态了会与管理节点的信号量冲突，
#会发生信号量冲突。后续版本若确实需要使用信号量，可以考虑重新定义规范的信号量体系来解决该问题
#

#
#当前为方便开发，补丁操作直接采取替换文件的方式。
#在正式发布稳定版本时，可以使用diff命令生成的补丁文件，进行规范的补丁操作
#

#oss最大的带宽 单位bytes/sec
oss_max_bandwidth=10485760
#在配置文件${config_path}/${config_name}中给出oss_max_bandwidth的值
#配置文件存储路径
config_path="/tmp/lustre/"
#配置文件名称
config_name="lustre_tbf_cfg"
#lustre/target/  修改已有文件

yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/Makefile/lustre_target_Makefile.am lustre/target/Makefile.am
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/Makefile/lustre_target_Makefile.in lustre/target/Makefile.in
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/tgt_handler.c lustre/target/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/tgt_main.c lustre/target/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/tgt_internal.h lustre/target/

#lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/Makefile/lustre_ptlrpc_Makefile.in lustre/ptlrpc/Makefile.in

#cp ${MULTEXU_SOURCE_DIR}/build/lfz/qos.h lustre/target/ 新增文件
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lfz.h lustre/target/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lfz.c lustre/target/

#lustre/
cp -rf ${MULTEXU_SOURCE_DIR}/build/lfz/metric-tests lustre/
#lustre/osc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/osc_request.c lustre/osc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lproc_osc.c lustre/osc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/osc_cache.c lustre/osc/
cp ${MULTEXU_SOURCE_DIR}/build/lfz/qos_rules.c lustre/osc/

#lustre/include/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/obd.h lustre/include/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lprocfs_status.h lustre/include/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lustre_nrs_tbf.h lustre/include/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lustre_net.h lustre/include/
cp ${MULTEXU_SOURCE_DIR}/build/lfz/metric.h lustre/include/

#lustre/include/lustre/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lustre_idl.h lustre/include/lustre/

#lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/pack_generic.c lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/nrs_tbf.c lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lproc_ptlrpc.c lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/service.c lustre/ptlrpc/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lustre_ptlrpc_wiretest.c lustre/ptlrpc/wiretest.c

#lustre/obdclass/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/genops.c lustre/obdclass/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lprocfs_status.c lustre/obdclass/
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/lprocfs_counters.c lustre/obdclass/

#lustre/utils/
#yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/tgt_handler.c lustre/target/

#lustre/target/

#Makefile文件
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/Makefile/lustre_include_Makefile.am lustre/include/Makefile.am
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/Makefile/lustre_include_Makefile.in lustre/include/Makefile.in
yes | cp ${MULTEXU_SOURCE_DIR}/build/lfz/Makefile/lustre_osc_Makefile.in lustre/osc/Makefile.in

sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd='mkdir -p ${config_path}'
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd='touch ${config_path}/${config_name}'
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd='echo ${oss_max_bandwidth} >  ${config_path}/${config_name}'
