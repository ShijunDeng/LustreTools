# vim excuse.sh
#!/bin/bash
LUSPINF_TOOL_DIR="/tmp/luspinfTools"
#声明环境变量
export PATH="/usr/lib/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"
#通过for循环,批量执行被管理机上的配置脚本
command_var="sh ${MULTEXU_BATCH_AUTHORIZE_DIR}/nodes_authorize.sh"
for host_ip in $(cat ${MULTEXU_BATCH_CONFIG_DIR}/nodes_authorize.out)
do
    ssh -f ${host_ip} "${command_var}"
done
