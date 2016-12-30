#!/bin/bash
# POSIX
#
#description:    patching for lustre
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-12-13
#

#
#这里暂时不要使用信号量，因为管理节点一直在周期性检测执行结果状态了会与管理节点的信号量冲突，
#会发生信号量冲突。后续版本若确实需要使用信号量，可以考虑重新定义规范的信号量体系来解决该问题
#

#自定义补丁操作和相应的补丁文件
#sh ${MULTEXU_BATCH_BUILD_DIR}/__patch_lfz.sh
sh ${MULTEXU_BATCH_BUILD_DIR}/__patch_metric.sh
exit 0