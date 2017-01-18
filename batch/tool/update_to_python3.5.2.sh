 #!/bin/bash
# POSIX
#
#description:    update python to version 3.5.2
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-12-29
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
clear_execute_statu_signal

print_message "MULTEXU_INFO" "Now start to update python..."
cd ${MULTEXU_SOURCE_TOOL_DIR}
print_message "MULTEXU_INFO" "Entering directory ${MULTEXU_SOURCE_TOOL_DIR}..."
xz -d Python-3.5.2.tar.xz 
tar -xvf Python-3.5.2.tar 
mkdir /usr/local/python3.5.2
cd Python-3.5.2/
./configure --prefix=/usr/local/python3.5.2
make
make install
wait
echo yes | mv /usr/bin/python /usr/bin/python.bak
ln -s /usr/local/python3.5.2/bin/python3.5 /usr/bin/python
echo yes | mv /usr/local/bin/python /usr/local/bin/python.bak
ln -s /usr/bin/python /usr/local/bin/python 

sed -i "s/\/usr\/bin\/python/\/usr\/bin\/python2.7/g" /usr/bin/yum
send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "Please check /usr/bin/yum manually..."
print_message "MULTEXU_INFO" "Leaving directory ${MULTEXU_SOURCE_TOOL_DIR}..."
print_message "MULTEXU_INFO" "finished to update python..."
