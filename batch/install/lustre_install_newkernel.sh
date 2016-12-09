#!/bin/bash
# POSIX
#
#description:    install lustre new kernel
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

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"                                                                     
clear_execute_statu_signal

print_message "MULTEXU_INFO" "install dependencies..."                                       
print_message "MULTEXU_INFO" "enter directory $( dirname "${BASH_SOURCE[0]}" )..."
`${PAUSE_CMD}`

yum -y groupinstall "Development Tools"
wait
yum -y install xmlto asciidoc elfutils-libelf-devel zlib-devel binutils-devel newt-devel python-devel hmaccalc perl-ExtUtils-Embed bison elfutils-devel audit-libs-devel  kernel-devel
wait
print_message "MULTEXU_INFO" "finished installing dependencies..."

`${PAUSE_CMD}`

cd "${MULTEXU_SOURCE_DIR}"/install
print_message "MULTEXU_INFO" "enter directory ${MULTEXU_SOURCE_DIR}..."
print_message "MULTEXU_INFO" "1. rpm -ivh --force kernel-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64-1.x86_64.rpm"
print_message "MULTEXU_INFO" "2. /sbin/new-kernel-pkg --package kernel --mkinitrd --dracut --depmod --install 3.10.0-3.10.0-327.3.1.el7_lustre.x86_64"
rpm -ivh --force kernel-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64*.rpm
wait
/sbin/new-kernel-pkg --package kernel --mkinitrd --dracut --depmod --install 3.10.0-3.10.0-327.3.1.el7_lustre.x86_64
wait

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "leave directory $( dirname "${BASH_SOURCE[0]}" )"
`${PAUSE_CMD}`
exit 0

