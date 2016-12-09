#!/bin/bash
# POSIX
#
#description:    install lustre server
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

rpm -ivh lustre-modules* --nodeps --force
wait
rpm -e --nodeps `rpm -qa | grep  libcom_err`
wait
rpm -Uvh libcom_err*
wait

rpm -e --nodeps `rpm -qa | grep   e2fsprogs-libs`
wait
rpm -Uvh  e2fsprogs-libs*
wait

rpm -e --nodeps `rpm -qa | grep  e2fsprogs-[^lib]*`
wait
rpm -Uvh e2fsprogs-[^lib]*  --nodeps --force
wait

rpm -Uvh libss*  --nodeps --force
wait

#rpm -ivh lustre-ldiskfs*  --nodeps --force
#wait
rpm -ivh lustre-osd-ldiskfs-2.8.0*  --nodeps --force
wait
rpm -ivh lustre-osd-ldiskfs-mount* --nodeps --force
wait

rpm -ivh lustre-2.8.0* --nodeps --force
wait
#lustre-modules-2.8.0-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64.x86_64 has missing requires of kernel = ('0', '3.10.0', '3.10.0-327.3.1.el7_lustre')
#yum clean all &&yum update glibc glibc-headers glibc-devel nscd && yum update
wait
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "leave directory $( dirname "${BASH_SOURCE[0]}" )..."

`${PAUSE_CMD}`