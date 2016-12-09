#!/bin/bash
# POSIX
#
#description:    test lustre nrs policy
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-09-08
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

#时间同步服务器
time_syn_clock=192.168.3.104

sleeptime=20 #设置检测的睡眠时间
limit=10 #递减下限

#测试结果存放目录
result_dir="testResult"

#测试参数
#test parameters
blocksize=1 #the blocksize
#测试目录
directory="/mnt/lustre/test"
direct=0
iodepth=5
allow_mounted_write=1
ioengine="sync"
special_cmd='-rwmixread=50' #随机IO时的一些特殊参数
size="1G"
numjobs=2
runtime=600
name="sscdt_test"

blocksize_start=1
blocksize_end=2048
blocksize_multi_step=2
#设置检测测试是否结束的时间以及检测的下限
checktime_init=600
checktime_lower_limit=60
#IO方式
declare -a rw_array;#Type of I/O pattern. 

#fio的读写方式
rw_array[0]="randrw"
rw_array[1]="readwrite"
rw_array[2]="write"
rw_array[3]="randwrite"
rw_array[4]="read"
rw_array[5]="randread"

client_ip=
policy=

#调度算法的名称noop anticipatory [deadline] cfq tb new_sysdeadline
declare -a policy_name

#
#默认是以空格分割 所以用连字符先代替一下 后面再替换
#
policy_name[0]="tbf-jobid"
policy_name[1]="crrn-pid"
policy_name[2]="orr-pid"

#获取参数值
function get_parameter()
{
    while :; 
    do
        case $1 in
            -f=?*|--fio_cmd=?*) #特殊附加命令
                special_cmd=${1#*=}
                shift
                ;;
            -f|--fio_cmd=) # Handle the case of an empty 
                printf 'MULTEXU ERROR: "-f|--fio_cmd" requires a non-empty option argument.\n' >&2
                exit 1
                ;;
            -?*)
                printf 'MULTEXU WARN: Unknown option (ignored): %s\n' "$1" >&2
                shift
                ;;
            *)    # Default case: If no more options then break out of the loop.
                shift
                break
        esac
    done
}
get_parameter $@

sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_available=nodes_all.out
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --test_host_ssh_enabled=nodes_all.out
`${PAUSE_CMD}`
#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"

#获取客户端的ip地址,只需要其中一个即可,用作向服务器发命令,清除测试产生的文件
for ip in $(cat ${MULTEXU_BATCH_CONFIG_DIR}/nodes_client.out)
do
    client_ip=${ip}
    break
done
#
#安装fio
#
print_message "MULTEXU_INFO" "now start to check fio tool in client nodes..."
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --supercmd="sh ${MULTEXU_BATCH_TEST_DIR}/fio_install.sh"
ssh_check_cluster_status "nodes_client.out" "${MULTEXU_STATUS_EXECUTE}" $((sleeptime/2)) ${limit}
print_message "MULTEXU_INFO" "finished fio checking..."
`${PAUSE_CMD}`
#清除信号量  避免干扰
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"

#
#删除oss上因为测试产生的文件和测试目录
#
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${client_ip} --cmd="rm -rf ${directory}"
sleep ${sleeptime}s
#建立测试目录
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${client_ip} --cmd="mkdir ${directory}/"
#设置lustre的stripe
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${client_ip} --cmd="lfs setstripe -c -1 ${directory}"
print_message "MULTEXU_INFO" "all ost have been used..."
`${PAUSE_CMD}`

cd ${MULTEXU_BATCH_TEST_DIR}/
print_message "MULTEXU_INFO" "enter directory ${MULTEXU_BATCH_TEST_DIR}..."
`${PAUSE_CMD}`
rm -rf "${result_dir}"

#定时清除服务器上的日志,因为测试的过程中会产生大量的日志,很可能会占用大量的日志空间或者影响服务器的性能
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="sh ${MULTEXU_BATCH_TEST_DIR}/clear_var_log_messages.sh"
print_message "MULTEXU_INFO" "the script clear_var_log_messages.sh is running in ipall.out set..."
#
#开始测试
#
print_message "MULTEXU_INFO" "now start the test processes..."
for policy in ${policy_name[*]}
do
	#修改调度器 并显示修改后的调度器名称  注意调度器实际命令需要引号 故传入的参数需要转义
    sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_oss.out --supercmd="lctl set_param ost.OSS.ost_io.nrs_policies=\"${policy/-/ }\""
	print_message "MULTEXU_INFO" "policy_name:${policy/-/ }"
    for rw_pattern in ${rw_array[*]}
    do
        #测试结果的存放目录
		dirname="${result_dir}/${rw_pattern}"
		
        if [ ! -d "${dirname}" ]; then
            mkdir -p ${dirname}
        fi
		print_message "MULTEXU_ECHO" "	rw_array:${rw_pattern}"
        for ((blocksize=${blocksize_start} ;blocksize <= ${blocksize_end}; blocksize*=${blocksize_multi_step}))
        do
            print_message "MULTEXU_ECHO" "		start a test..."   
			
            special_cmd_io_choice=
			
            if [[ ${rw_pattern} == "readwrite" ]] || [[ ${rw_pattern} == "randrw" ]];then
                special_cmd_io_choice=${special_cmd}
            fi

            cmdvar="${MULTEXU_SOURCE_DIR}/tool/fio/fio -directory=${directory} -direct=${direct} -iodepth ${iodepth} -thread -rw=${rw_pattern} ${special_cmd_io_choice} -allow_mounted_write=${allow_mounted_write} -ioengine=${ioengine} -bs=${blocksize}k -size=${size} -numjobs=${numjobs} -runtime=${runtime} -group_reporting -name=${name} "
            print_message "MULTEXU_ECHO" "		test command:${cmdvar}"
            #删除测试文件
            sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${client_ip} --cmd="rm -f ${directory}/*"
			
			####时间同步
            sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_all.out --cmd="rdate -s ${time_syn_clock}"
			####
			
			sleep ${sleeptime}s
            #测试结果文件名称,组成方式:读写模式-调度器-块大小-k.txt
            filename="${rw_pattern}-${policy}-${blocksize}-k.txt"
            touch "${dirname}/${filename}"
            `${PAUSE_CMD}`    
            echo "${cmdvar}" > ${dirname}/${filename}
            #测试结果写入文件
            sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --supercmd="sh "${MULTEXU_BATCH_TEST_DIR}"/_test_exe.sh \"${cmdvar}\" " >> ${dirname}/${filename}
            #检测测试是否完成
            ssh_check_cluster_status "nodes_client.out" "${MULTEXU_STATUS_EXECUTE}" ${checktime_init} ${checktime_lower_limit}
            #清除标记
            sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"            
            print_message "MULTEXU_ECHO" "		finish this test..."
            `${PAUSE_CMD}`
        done #blocksize
    done #rw_pattern
done #policy

sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=nodes_client.out --cmd="sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh  --clear_execute_statu_signal"
#清除测试产生的垃圾文件
sh ${MULTEXU_BATCH_CRTL_DIR}/multexu.sh --iptable=${client_ip} --cmd="rm -f ${directory}/*"
`${PAUSE_CMD}`

print_message "MULTEXU_INFO" "all test jobs has been finished..."
exit 0
