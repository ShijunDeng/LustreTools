 #!/bin/bash
# POSIX
#
#description:    install GNU parallel shell tool
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

print_message "MULTEXU_INFO" "Now start to install GNU parallel shell tool..."
cd ${MULTEXU_SOURCE_TOOL_DIR}
print_message "MULTEXU_INFO" "Entering directory ${MULTEXU_SOURCE_TOOL_DIR}..."
tar -jxvf parallel-20161222.tar.bz2 
cd parallel-20161222
./configure 
make
make install
wait

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "Leaving directory ${MULTEXU_SOURCE_TOOL_DIR}..."
print_message "MULTEXU_INFO" "finished to install GNU parallel shell tool..."
