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
