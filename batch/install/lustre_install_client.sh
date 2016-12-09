#!/bin/bash
# POSIX
#
#description:    install lustre client
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-24

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
                                                              
print_message "MULTEXU_INFO" "install dependencies..."                                       
cd "${MULTEXU_SOURCE_DIR}"/install
print_message "MULTEXU_INFO" "enter directory ${MULTEXU_SOURCE_DIR}/install..."

rpm -ivh lustre-client-modules?*.rpm --nodeps --force
wait
rpm -ivh lustre-client-2.8?*.rpm --nodeps --force
wait
rpm -ivh lustre-modules* --nodeps --force
wait
#lustre-modules-2.8.0-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64.x86_64 has missing requires of kernel = ('0', '3.10.0', '3.10.0-327.3.1.el7_lustre')
#yum clean all &&yum update glibc glibc-headers glibc-devel nscd && yum update
wait

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "leave directory $( dirname "${BASH_SOURCE[0]}" )..."
print_message "MULTEXU_INFO" "all jobs finished"
#加载模块
modprobe lustre
exit 0
