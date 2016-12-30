#!/bin/sh
#POSIX
#

#description:    start distributed filesystem automatic I/O congestion control
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-12-28
#
#运行本脚本时,假设主控制节点与所有节点(包括编译节点)已经进行SSH认证
#

sleeptime=60 #设置检测的睡眠时间
limit=10 #递减下限

#
#计算程序运行的时间
#
start_time=$(date +%s%N)
start_time_ms=${start_time:0:16}

#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f __init.sh ]; then
	echo "MULTEXU Error:initialization failure:cannot find the file __init.sh... "
	exit 1
else
	source ../__init.sh
	echo 'MULTEXU INFO:initialization completed...'
	`${PAUSE_CMD}`
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"

#参数选项



while :;
do
    case $1 in
        --skip_build_kernel=?*)
            skip_build_kernel=${1#*=}
            shift
            ;;
        --goto_compile=?*)
            goto_compile=${1#*=}
            shift
            ;;
        --only_pre=?*)
            only_pre=${1#*=}
            shift
            ;;
        --install_lmt=?*)
            install_lmt=${1#*=}
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

function benchmark_rule() 
{

}


function get_best_score()
{

}

#############################################################################################
#										开始AIOCC											
#############################################################################################
print_message "MULTEXU_INFO" "Now start AIOCC ..."
print_message "MULTEXU_INFO" "Now start AIOCC ..."



#计算程序运行的时间
end_time=$(date +%s%N)
end_time_ms=${end_time:0:16}
#scale=6
time_cost=0
time_cost=`echo "scale=6;($end_time_ms - $start_time_ms)/1000000" | bc` 
print_message "MULTEXU_INFO" "AIOCC process finished..."
print_message "MULTEXU_INFO" "Total time spent:${time_cost} s"


