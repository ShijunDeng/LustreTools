#!/bin/bash
# POSIX
#
#description:    set max bandwidth of oss node
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-12-17
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
config_path="/tmp/lustre"
#配置文件名称
config_name="lustre_tbf_cfg"
#lustre/target/  修改已有文件
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="mkdir -p ${config_path}"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="touch ${config_path}/${config_name}"
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="echo ${oss_max_bandwidth} >  ${config_path}/${config_name}"
