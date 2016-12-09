#!/bin/bash
# POSIX
#
#description:    clear logs
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-19
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

VAR_LOG_DIR="/var/log"
count=0
count_limit=$1
if [ ! -n ${count_limit} ]; then 
    count_limit=48
fi

while [[ count -lt ${count_limit} ]]
do
    echo '' > ${VAR_LOG_DIR}/messages
    print_message "MULTEXU_INFO"  "the ${count} time clear ${VAR_LOG_DIR}/messages"
    let count+=1
    sleep 3600s
done

