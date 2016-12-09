#!/bin/bash
# POSIX
#
#description:    pre-setting:selinux client-aliveinterval 
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-24
#
#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
    echo "MULTEXU Error:multexu initialization failure:cannot find the file __init.sh... "
    exit 1
else
    source ../ctrl/__init.sh
fi

source "${MULTEXU_BATCH_CRTL_DIR}"/multexu_lib.sh #调入multexu库
clear_execute_statu_signal

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
print_message "MULTEXU_INFO" "set SELINUX=disabled"
systemctl stop firewalld
#systemctl stop firewalld.service && sudo systemctl disable firewalld.service
systemctl mask firewalld
#Then, install the iptables-services package:
yum -y install iptables-services
#Enable the service at boot-time:
systemctl enable iptables
#Managing the service
#systemctl [stop|start|restart] iptables
systemctl stop iptables
#Saving your firewall rules can be done as follows:
service iptables save
#    or   /usr/libexec/iptables/iptables.init save
#chkconfig iptables off
print_message "MULTEXU_INFO" "disable iptables firewall... "
#service iptables stop
print_message "MULTEXU_INFO" "service iptables stoped ..."

#yum clean metadata 
#yum clean dbcache  
#yum makecache

echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "leave directory $( dirname "${BASH_SOURCE[0]}" )"
