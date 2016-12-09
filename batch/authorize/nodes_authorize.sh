# vim ClientAuthorize.sh
#!/bin/bash
#
#description:   a simple uniform tools for authorization
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-20
#

#声明环境变量
export PATH="/usr/lib/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"

#检查所需目录及文件,如果没有就创建一个
if [ ! -d /root/.ssh ];then
    mkdir /root/.ssh
fi

if [ ! -f /root/.ssh/authorized_keys ];then
    touch /root/.ssh/authorizedzz_keys
fi

setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
echo "MULTEXU INFO:set SELINUX=disabled"

#设置被管理机的相关目录文件权限
chmod go-w /root
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
 
#set authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQComV783ySYVkiyF8AbJs0bQQFSwUv0cIpyu9RFFmVh3L5e2xvcsJkITUawIDq5dCa7cCL+z0zpL1RhwCjc0xOVwvsfzekWG6F3+8k5iEbatr3yxOuM1l8ZxnXnc8WUaHfcadbOMj1z0oJ1p8soqH4Y4Tll28Y0DOdFKRa+G8kbjxJSLGJJVc4oEBj9CNiJf8P36wRA2yW2hlTFVINBPsgykcI87Uhq7iEEXpzZ41UAkpMSLfWlcBGmT0Njo/2lUb0cuPoiMPT1O8mY/3hRrKRDNxS2w45ZpEgUMAbyUm92nZ1LAOFC7/F0u0Q7hbor+xIme3uW2YaOovmObA69XukP root@localhost.localdomain" >> /root/.ssh/authorized_keys
