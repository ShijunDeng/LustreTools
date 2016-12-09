#!/bin/bash
# POSIX
#
#description:    build lustre 2.8.0 automaticlly [bew kernel]
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-09-01
#
#initialization


#
#这份脚本用于编译针对Lustre的Linux内核以及Lustre,并配合一些手动操作,最终生成相关的rpm包
#建议在一台机器上编译,然后将生成的rpm用于相同配置的其它机器上,方便快速部署
#脚本运行结束后,请根据提示手动执行：
#1. rpm -ivh --force kernel-xxx.rpm
#2. /sbin/new-kernel-pkg --package kernel --mkinitrd --dracut --depmod --install xxx
#3. reboot
#以安装新的内核并重启
#完成重启后,运行build_lustre.sh完成Lustre的编译
#

echo -e "这份脚本用于编译针对Lustre的Linux内核以及Lustre,并配合一些手动操作,最终生成相关的rpm包
建议在一台机器上编译,然后将生成的rpm用于相同配置的其它机器上,方便快速部署
脚本运行结束后,请根据提示手动执行：
1. rpm -ivh --force kernel-xxx.rpm
2. /sbin/new-kernel-pkg --package kernel --mkinitrd --dracut --depmod --install xxx
3. reboot\n
以安装新的内核并重启
完成重启后,运行build_lustre.sh完成Lustre的编译"


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

mkdir -p "${BUILD_BASE_DIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cd kernel
print_message "MULTEXU_INFO" "install dependencies..."  

#
#             yum -y install quilt
#
#wget http://mirror.centos.org/centos/7/os/x86_64/Packages/newt-devel-0.52.15-4.el7.x86_64.rpm
#wget http://mirror.centos.org/centos/7/os/x86_64/Packages/slang-devel-2.2.4-11.el7.x86_64.rpm
#wget http://mirror.centos.org/centos/7/os/x86_64/Packages/asciidoc-8.6.8-5.el7.noarch.rpm
yum -y --nogpgcheck localinstall ${MULTEXU_SOURCE_DIR}/build/newt-devel-0.52.15-4.el7.x86_64.rpm ${MULTEXU_SOURCE_DIR}/build/slang-devel-2.2.4-11.el7.x86_64.rpm  ${MULTEXU_SOURCE_DIR}/build/asciidoc-8.6.8-5.el7.noarch.rpm 
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

print_message "MULTEXU_INFO" "Now start to rpmbuild kernel ..."
echo '%_topdir %(echo $HOME)/kernel/rpmbuild' > ~/.rpmmacros
#
#rpm -ivh kernel-3.10.0-327.3.1.el7_lustre.src.rpm  2>&1 | grep -v exist
#
rpm -ivh ${MULTEXU_SOURCE_DIR}/build/kernel-3.10.0-327.3.1.el7_lustre.src.rpm  2>&1 | grep -v exist
wait
rpm -ivh ${MULTEXU_SOURCE_DIR}/build/lustre-2.8.0-3.10.0_327.3.1.el7_lustre.x86_64.src.rpm  2>&1 | grep -v exist
wait
print_message "MULTEXU_INFO" "Now start to rpmbuild kernel ..."

cd "${BUILD_BASE_DIR}"
rpmbuild -bp --target=`uname -m` ./SPECS/kernel.spec
sleep ${sleeptime}s
wait
#这里必须这样做,因为后面要用到其下的.config文件
rpmbuild -bp --target=`uname -m` ./SPECS/lustre.spec
sleep ${sleeptime}s
wait
#
#modify EXTRAVERSION = 
#
sed -i 's/EXTRAVERSION =/EXTRAVERSION = -3.10.0-327.3.1.el7_lustre.x86_64/g' "${BUILD_BASE_DIR}"/BUILD/kernel-3.10.0-327.3.1.el7/linux-3.10.0-327.3.1.el7.x86_64/Makefile


cd "${BUILD_BASE_DIR}"/BUILD/kernel-3.10.0-327.3.1.el7/linux-3.10.0-327.3.1.el7.x86_64/
print_message "MULTEXU_INFO" "enter directory:${BUILD_BASE_DIR}/BUILD/kernel-3.10.0-327.3.1.el7/linux-3.10.0-327.3.1.el7.x86_64/"

#
#该.config文件可以作为默认的编译配置文件，如果需要修改，请在编译内核的时候做出选择，并用make oldconfig或者make menuconfig配置
#
yes | cp "${BUILD_BASE_DIR}"/BUILD/lustre-2.8.0/lustre/kernel_patches/kernel_configs/kernel-3.10.0-3.10-rhel7-x86_64.config ./.config
#
#.config已经是我们配置(lustre提供的就可以)好的,这样在自动化的脚本中就不需要再进行确认,直接进行编译工作
#
#yes | cp "${BUILD_BASE_DIR}"/BUILD/lustre-2.8.0/lustre/kernel_patches/kernel_configs/.config ./.config
yes | cp ${MULTEXU_SOURCE_DIR}/build/raid5-mmp-unplug-dev-3.7.patch "${BUILD_BASE_DIR}"/BUILD/lustre-2.8.0/lustre/kernel_patches/patches/

#
#注意根据版本正确选择 xxx.series
#
ln -s "${BUILD_BASE_DIR}"/BUILD/lustre-2.8.0/lustre/kernel_patches/series/3.10-rhel7.series series
ln -s "${BUILD_BASE_DIR}"/BUILD/lustre-2.8.0/lustre/kernel_patches/patches patches
print_message "MULTEXU_INFO" "now start to patch the kernel ..."
quilt push -av
#quilt push -av的代替命令：for PATCH in $(cat series); do patch -p1 < patches/$PATCH; done
`${PAUSE_CMD}`
cd "${BUILD_BASE_DIR}"/BUILD/kernel-3.10.0-327.3.1.el7/linux-3.10.0-327.3.1.el7.x86_64/
#make oldconfig || make menuconfig
#make include/asm
#make include/linux/version.h
#make SUBDIRS=scripts
#make include/linux/utsrelease.h
#make rpm
print_message "MULTEXU_INFO" "now start to make rpm(new kernel)..."
read -p "choose default .config to continue to execute the command[make -j4 rpm] ?(y/n):" -t 10 choose
if [[ "${choose}" =~ ^n.*$ || "${choose}" =~ ^N.*$  ]];then
    exit 0;
fi
#make oldconfig
make -j4 rpm

print_message "MULTEXU_INFO" "finished to make rpm(new kernel)..."
print_message "MULTEXU_INFO" "please execute the following command manually..."
print_message "MULTEXU_INFO" "1. rpm -ivh --force kernel-3.10.0_3.10.0_327.3.1.el7_lustre.x86_64*.rpm"
#ls  /boot/  ==> System.map-3.10.0-3.10.0-327.3.1.el7_lustre.x86_64  ==> 3.10.0-3.10.0-327.3.1.el7_lustre.x86_64
print_message "MULTEXU_INFO" "2. /sbin/new-kernel-pkg --package kernel --mkinitrd --dracut --depmod --install 3.10.0-3.10.0-327.3.1.el7_lustre.x86_64"
print_message "MULTEXU_INFO" "3. reboot"
print_message "MULTEXU_INFO" "now you can run the script build_lustre[server/client].sh..."
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
exit 0




