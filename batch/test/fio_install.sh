#!/bin/bash
# POSIX
#
#description:    test lustre with[out] ascar
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-27
#
#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
    echo "MULTEXU Error:multexu initialization failure:cannot find the file __init.sh... "
    exit 1
else
    source ../ctrl/__init.sh
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"
`${PAUSE_CMD}`
#清除信号量  避免干扰
clear_execute_statu_signal

#
#如果fio目录存在,表示fio已经解压安装过;否则进行解压安装;
#
if [ ! -d ${MULTEXU_SOURCE_DIR}/tool/fio ] ;
then
    print_message "MULTEXU_INFO" "now start to install fio..."
    cd ${MULTEXU_SOURCE_DIR}/tool/

    yum -y install gtk2-devel 
    yum -y install glib2-devel
    tar -jxv -f fio.tar.bz2 -C ./
    #git clone git://git.kernel.dk/fio.git
    cd fio
    ./configure --enable-gfio
    make fio
    make gfio
	wait
fi

#置入执行信号量 代表fio安装完成
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
