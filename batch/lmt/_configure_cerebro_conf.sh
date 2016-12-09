#!/bin/bash
# POSIX
#
#description:    configure /etc/cerebro.conf(configure Lustre Monitoring Tool management node automaticlly)
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-10-19
#
#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
	echo "MULTEXU Error:initialization failure:cannot find the file __init.sh... "
	exit 1
else
	source ../ctrl/__init.sh
	echo 'MULTEXU INFO:initialization completed...'
	`${PAUSE_CMD}`
fi
source "${MULTEXU_BATCH_CRTL_DIR}"/multexu_lib.sh #调入multexu库
clear_execute_statu_signal

mdsnode=

#
#获取参数
#
while getopts 's:' opt;do
    case $opt in
        s)
            mdsnode=$OPTARG
            ;;
    esac
done
#配置metric-server 
sed -i "s/# cerebro_metric_server localhost/cerebro_metric_server ${mdsnode}/g" /etc/cerebro.conf
#配置event-server
for host_ip in $(cat ${MULTEXU_BATCH_CONFIG_DIR}/nodes_server.out)
do
    echo "cerebro_event_server ${host_ip}" >> /etc/cerebro.conf
done

send_execute_statu_signal "${MULTEXU_STATUS_EXECUTE}"
print_message "MULTEXU_INFO" "finished to configure /etc/cerebro.conf..."
`${PAUSE_CMD}`
