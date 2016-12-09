#!/bin/bash
# POSIX
#
#description:    build lustre 2.8.0 automaticlly [lustre client]
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-09-08
#
#initialization

sleeptime=60 #设置检测的睡眠时间
limit=10 #递减下限

cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
    echo "MULTEXU Error:initialization failure:cannot find the file __init.sh... "
    exit 1
else
    source ../ctrl/__init.sh
    echo 'MULTEXU INFO:initialization completed...'
    `${PAUSE_CMD}`
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"
clear_execute_statu_signal

#
#if you login in the system as root, after this command,then you will enter /root directory
#
cd $HOME
BUILD_BASE_DIR="$HOME""/kernel/rpmbuild"

#grep -Ri 'intel' /usr
#rpm -ivh $PKG_PATH/kernel-*.rpm
#/sbin/new-kernel-pkg --package kernel --mkinitrd --dracut --depmod --install 2.6.32.431.5.1.el6_lustre
#reboot
#多次重复编译时，不需要每次都安装依赖，可以指定此选项为1，跳过安装依赖以节约时间
skip_install_dependency=0
while :;
do
    case $1 in
        --skip_install_dependency=?*)
            skip_install_dependency=${1#*=}
            shift
            ;;
		-?*)
            printf 'WARN: Unknown option (ignored): %s\n' "(" >&2")"
            shift
            ;;
		*)	# Default case: If no more options then break out of the loop.
			shift
			break
	esac		
done

if [ ${skip_install_dependency} -eq 0 ];then 
    print_message "MULTEXU_INFO" "install dependencies..."  

    #
    #             yum -y install quilt
    #
    #wget http://mirror.centos.org/centos/7/os/x86_64/Packages/newt-devel-0.52.15-4.el7.x86_64.rpm
    #wget http://mirror.centos.org/centos/7/os/x86_64/Packages/slang-devel-2.2.4-11.el7.x86_64.rpm
    #wget http://mirror.centos.org/centos/7/os/x86_64/Packages/asciidoc-8.6.8-5.el7.noarch.rpm
    yum --nogpgcheck localinstall ${MULTEXU_SOURCE_DIR}/build/newt-devel-0.52.15-4.el7.x86_64.rpm ${MULTEXU_SOURCE_DIR}/build/slang-devel-2.2.4-11.el7.x86_64.rpm  ${MULTEXU_SOURCE_DIR}/build/asciidoc-8.6.8-5.el7.noarch.rpm 
    sleep ${sleeptime}s
    yum -y groupinstall "Development Tools"
    sleep ${sleeptime}s
    yum -y install xmlto 
    `${PAUSE_CMD}`
    yum -y install asciidoc 
    `${PAUSE_CMD}`
    yum -y install elfutils-libelf-devel 
    `${PAUSE_CMD}`
    yum -y install zlib-devel 
    `${PAUSE_CMD}`
    yum -y install binutils-devel
    `${PAUSE_CMD}`
    yum -y install newt-devel 
    `${PAUSE_CMD}`
    yum -y install python-devel 
    `${PAUSE_CMD}`
    yum -y install hmaccalc 
    `${PAUSE_CMD}`
    yum -y install perl-ExtUtils-Embed  
    `${PAUSE_CMD}`
    yum -y install python-docutils 
    `${PAUSE_CMD}`
    yum -y install elfutils-devel 
    `${PAUSE_CMD}`
    yum -y install audit-libs-devel 
    `${PAUSE_CMD}`
    yum -y install libselinux-devel 
    `${PAUSE_CMD}`
    yum -y install ncurses-devel 
    `${PAUSE_CMD}`
    yum -y install pesign 
    yum -y install numactl-devel 
    `${PAUSE_CMD}`
    yum -y install pciutils-devel 
    `${PAUSE_CMD}`
    yum -y install quilt
    sleep ${sleeptime}s
    wait

    #wget https://mirrors.ustc.edu.cn/fedora/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
    rpm -ivh ${MULTEXU_SOURCE_DIR}/build/epel-release-7-8.noarch.rpm 
fi

echo '%_topdir %(echo $HOME)/kernel/rpmbuild' > ~/.rpmmacros
rpm -ivh ${MULTEXU_SOURCE_DIR}/build/lustre-client-2.8.0-3.10.0_327.3.1.el7.x86_64.src.rpm  2>&1 | grep -v exist
wait
print_message "MULTEXU_INFO" "Now start to rpmbuild  lustre(client)..."

cd "${BUILD_BASE_DIR}"
rpmbuild -bp --target=`uname -m` ./SPECS/lustre.spec
sleep ${sleeptime}s
wait

cd "${BUILD_BASE_DIR}"/BUILD/lustre-2.8.0/

print_message "MULTEXU_INFO" "now start to patch the lustre ..."
#patch -p1 < ${MULTEXU_SOURCE_DIR}/build/lustre_nrs_sscdt.patch
#patch -p1 < ${MULTEXU_SOURCE_DIR}/build/lustre_qos.patch
`${PAUSE_CMD}`
print_message "MULTEXU_INFO" "now start to patch files for metric ..."
sh ${MULTEXU_BATCH_BUILD_DIR}/_patch_metric.sh
`${PAUSE_CMD}`

#注意--with-linux指定的位置
./configure --with-linux="${BUILD_BASE_DIR}"/BUILD/kernel-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64/ --disable-server  
make rpms -j8
print_message "MULTEXU_INFO" "finished to make rpms (client) ..."
`${PAUSE_CMD}`
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
exit 0


