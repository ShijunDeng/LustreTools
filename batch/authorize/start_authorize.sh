#!/bin/bash
#
#description:    a simple uniform tools for authorization
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-20
#

#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )"
if [ ! -f ../ctrl/__init.sh ]; then
    echo " multexu initialization failure:cannot find the file __init.sh... "
    exit 1
else
    source ../ctrl/__init.sh
fi

#声明环境变量
export PATH="/usr/lib/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"
#生成管理机的公私钥
ssh-keygen
#设置管理机的相关目录权限
chmod go-w /root
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
#将生成的公钥信息导入nodes_authorize.sh脚本中
rsapub_var=$(cat /root/.ssh/id_rsa.pub)
cp ${MULTEXU_BATCH_AUTHORIZE_DIR}/nodes_authorize.sh.origin ${MULTEXU_BATCH_AUTHORIZE_DIR}/nodes_authorize.sh
echo " " >> ${MULTEXU_BATCH_AUTHORIZE_DIR}/nodes_authorize.sh
echo "#set authorized_keys" >> ${MULTEXU_BATCH_AUTHORIZE_DIR}/nodes_authorize.sh
echo "echo \""${rsapub_var}"\" >> /root/.ssh/authorized_keys" >> ${MULTEXU_BATCH_AUTHORIZE_DIR}/nodes_authorize.sh

chmod u+x ${MULTEXU_BATCH_AUTHORIZE_DIR}/nodes_authorize.sh

#调用批量分发脚本,如果执行成功,就继续调用批量执行脚本
sh ${MULTEXU_BATCH_AUTHORIZE_DIR}/distribute.sh && sh ${MULTEXU_BATCH_AUTHORIZE_DIR}/execuse.sh

echo "MULTEXU INFO:the nodes in nodes_authorize.out are going to reboot ..." 
for ip_var in $(cat "${MULTEXU_BATCH_CONFIG_DIR}"/nodes_authorize.out)
do
    ssh -f ${ip_var} reboot
done

exit 0
