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
if [ ! -f ./__aiocc_init.sh ]; then
	echo "AIOCC Error:initialization failure:cannot find the file __aiocc_init.sh... "
	exit 1
else
	source ./__aiocc_init.sh
	echo 'AIOCC INFO:initialization completed...'
	`${PAUSE_CMD}`
fi

source "${MULTEXU_BATCH_CRTL_DIR}/multexu_lib.sh"
clear_execute_statu_signal 
clear_execute_statu_signal ${AIOCC_EXECUTE_SIGNAL_FILE}

OS_TYPE="X64"
MAX_INT=18446744073709551615

#EPOCH_DIR_PREFIX="epoch_" 
#搜索策略
SEARCH_POLICY=""
#是否指定初始规则,如指定初始规则,应该在调用本脚本前,将规则的参数值写入initial.rule文件中
INITIAL_RULE=0
CATEGORY="default"
#控制参数<m,b,t>中的m
ENABLE_M=0
#是否保留旧的测试文件
KEEP_OLD_TESTFILES=0
DROP_CACHE=0

AIOCC_RULE_DATABASE_DIR=""
AIOCC_RULE_CANDIDATE_DIR=""
AIOCC_RULE_TESTED_DIR=""
AIOCC_RULE_RESULT_DIR=""


MAX_BW_FILE=
#参数选项
while :;
do
    case $1 in
        --search_policy=?*)
            search_policy=${1#*=}
            shift
            ;;
        --category=?*)
            CATEGORY=${1#*=}
            shift
            ;;
		--initial_rule=?*)
            INITIAL_RULE=${1#*=}
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

function __initialize()
{
	if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ] ; then
		OS_TYPE="X64"
		MAX_INT=18446744073709551615
	else
		OS_TYPE="X32"
		MAX_INT=2147483647
		print_message "MULTEXU_WARN" "Pay attention to the OS_TYPE:${OS_TYPE},X64 is suggested..."
	fi
	
	AIOCC_RULE_DATABASE_DIR="${AIOCC_RULE_DIR}/${CATEGORY}"
	AIOCC_RULE_CANDIDATE_DIR="${AIOCC_RULE_DATABASE_DIR}/candidate_rules"
	AIOCC_RULE_TESTED_DIR="${AIOCC_RULE_DATABASE_DIR}/tested_rules" 
	AIOCC_RULE_RESULT_DIR="${AIOCC_RULE_DATABASE_DIR}/results" 
	auto_mkdir ${AIOCC_RULE_DATABASE_DIR} "weak"
	auto_mkdir ${AIOCC_RULE_CANDIDATE_DIR} "weak"
	auto_mkdir ${AIOCC_RULE_TESTED_DIR} "weak"
	auto_mkdir ${AIOCC_RULE_RESULT_DIR} "weak"
	clear_execute_statu_signal ${AIOCC_CTROL_SIGNAL_FILE}
}
#
#RET_VAR CANDIDATE ROUND_SUMMARY_FILE
#
function optimize_rule() 
{
	local RET_VAR=$1
    local CANDIDATE=$2
    local ROUND_SUMMARY_FILE=$3
    # 删除测试的旧文件
    if [ $KEEP_OLD_TESTFILES -eq 0 ]; then
        rm -f ${MULTEXU_CLIENT_MNT_DIR}/ior-test-file*
        rm -f ${MULTEXU_CLIENT_MNT_DIR}/btio.*.out
        rm -rf ${MULTEXU_CLIENT_MNT_DIR}/fbench*
    fi
	`${PAUSE_CMD}`
    if [ $DROP_CACHE -eq 1 ]; then
        # drop server-side cache
		sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh --iptable=nodes_oss.out --cmd='echo 3 > /proc/sys/vm/drop_caches'
    fi
	
	#
	#主要要在/etc/fstab中配置相关信息 才能使用这两条命令
	#
	#sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh --iptable=nodes_client.out --cmd='unmount ${MULTEXU_CLIENT_MNT_DIR}'
    `${PAUSE_CMD}`
	#sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh --iptable=nodes_client.out --cmd='mount ${MULTEXU_CLIENT_MNT_DIR}'
	
    if [ $DROP_CACHE -eq 1 ]; then
        # disable client readahead after each mount (not sure if this is needed, but do it anyway)
       sh ${MULTEXU_BATCH_CRTL_DIR}/multexu_ssh.sh --iptable=nodes_client.out --cmd='echo 3 > /proc/sys/vm/drop_caches'
    fi
    sleep 3

    local RULE_TO_USE
    if [ -f "${AIOCC_RULE_CANDIDATE_DIR}/${CANDIDATE}" ]; then
        RULE_TO_USE="${AIOCC_RULE_CANDIDATE_DIR}/${CANDIDATE}"
    else
        RULE_TO_USE="${AIOCC_RULE_TESTED_DIR}/${CANDIDATE}/summary"
    fi
    #发送rule到各个client节点 参数 "${RULE_TO_USE}"
	sh /home/development/LustreTools/batch/ctrl/multexu.sh --iptable=nodes_all.out --sendfile=${RULE_TO_USE} --location=${RULE_TO_USE}
    # SCORE_LINE format: ${RULE_NO},${SCORE},${CANDIDATE_AVG_BW},${CANDIDATE_AVG_VAR},${CANDIDATE_TRIED_TIMES}
    local OLD_SCORE_LINE=`grep "^${CANDIDATE}," $ROUND_SUMMARY_FILE`
    if [ x$OLD_SCORE_LINE = x ]; then
        local CANDIDATE_AVG_BW=0
        local CANDIDATE_AVG_VAR=0
        local CANDIDATE_TRY=0
    else
        local CANDIDATE_AVG_BW=`echo $OLD_SCORE_LINE | cut -d, -f 3`
        local CANDIDATE_AVG_VAR=`echo $OLD_SCORE_LINE | cut -d, -f 4`
        local CANDIDATE_TRY=`echo $OLD_SCORE_LINE | cut -d, -f 5`
    fi
    CANDIDATE_TRY=$(( $CANDIDATE_TRY + 1 ))

    if [ $CANDIDATE_TRY -eq 1 ]; then	
        local OUTPUT_DIR="${AIOCC_RULE_RESULT_DIR}/${CANDIDATE}"
        if [ -d "$OUTPUT_DIR" ]; then
            # delete old results (they are mostly half finished anyway)
            rm -rf "$OUTPUT_DIR"
        fi
    else
        local OUTPUT_DIR="${CANDIDATE}/${CANDIDATE_TRY}"
    fi
	
	auto_mkdir "$OUTPUT_DIR" "weak" 
	
    1>&2 echo "Benchmarking rule $CANDIDATE start"
    local TEST_OUT_FILE=${OUTPUT_DIR}/test.out
    if ! $WORKLOAD -o "${OUTPUT_DIR}" &>"$TEST_OUT_FILE"; then
        RC=$?
        1>&2 echo "Benchmarking rule $CANDIDATE failed with error code $RC"
        FAILURES=$(( $FAILURES + 1 ))
        return 2
    else
        1>&2 echo "Benchmarking rule $CANDIDATE succeeded"
    fi
    # Get the qos_rules from the all clients, which contains
    # used_times and {ack,send}_ewma_avg
	auto_mkdir "${AIOCC_RULE_TESTED_DIR}/${CANDIDATE}" "weak" 
    # We only gather the first try's QoS trigger data
    if [ $CANDIDATE_TRY -eq 1 ]; then
		clear_execute_statu_signal
        sh ${AIOCC_BATCH_DIR}/gather_qos_rules.sh "${AIOCC_RULE_TESTED_DIR}/${CANDIDATE}"
		local_check_status "${AIOCC_EXECUTE_STATUS_FINISHED}"  1 1
		
        ./merge_qos_rules_files.py "${AIOCC_RULE_TESTED_DIR}/${CANDIDATE}/summary" "${AIOCC_RULE_TESTED_DIR}/${CANDIDATE}"/*.qos_rules
    fi

    # get merit score
    # Rounded bandwidth
	clear_execute_statu_signal
	sh ${AIOCC_BATCH_DIR}/extract_bandwidth.sh "$OUTPUT_DIR"
	local_check_status "${AIOCC_EXECUTE_STATUS_FINISHED}" 1 1
    local BANDWIDTH=`grep 'bandwidth_mean' $OUTPUT_DIR/bandwidth.statistic | cud -d : -f 2`
    if [ x$BANDWIDTH = x -o $BANDWIDTH -eq 0 ]; then
        1>&2 echo "Cannot get bandwidth, error"
        FAILURES=$(( $FAILURES + 1 ))
        return
    else
        CANDIDATE_AVG_BW=`echo "( $CANDIDATE_AVG_BW * ( $CANDIDATE_TRY - 1 ) + $BANDWIDTH ) / $CANDIDATE_TRY" | bc`
        if [ $CANDIDATE_AVG_BW -gt $MAX_BW ]; then
            MAX_BW=$CANDIDATE_AVG_BW
            echo $MAX_BW >$MAX_BW_FILE
        fi
    fi
  
    local VAR=`grep 'bandwidth_stddev' $OUTPUT_DIR/bandwidth.statistic | cud -d : -f 2`
	if [ x$VAR = x ]; then
		VAR=0
	fi

    CANDIDATE_AVG_VAR=`echo "( $CANDIDATE_AVG_VAR * ( $CANDIDATE_TRY - 1 ) + $VAR ) / $CANDIDATE_TRY" | bc`
    SCORE=`${WORKLOAD_BIN_DIR}/calculate_score.py $CANDIDATE_AVG_BW $CANDIDATE_AVG_VAR`
    SCORE_LINE=${CANDIDATE},${SCORE},${CANDIDATE_AVG_BW},${CANDIDATE_AVG_VAR},${CANDIDATE_TRY}

    # update ROUND_SUMMARY_FILE
    if grep -q "^${CANDIDATE}," $ROUND_SUMMARY_FILE; then
        sed -i "s/^${CANDIDATE},.*/${SCORE_LINE}/g" $ROUND_SUMMARY_FILE
    else
        echo "$SCORE_LINE" >>$ROUND_SUMMARY_FILE
    fi

    local VAR_PER=`echo "100 * $CANDIDATE_AVG_VAR / $CANDIDATE_AVG_BW" | bc`
    eval "$RET_VAR='${VAR_PER},${CANDIDATE_TRY}'"
}

# 测试候选规则(${AIOCC_RULE_CANDIDATE_DIR})下的规则,并将测试的结果存储在
# $RESULTS_DIR下和$ROUND_SUMMARY_FILE中,
# 评估最高的score存储在$1并返回
function get_best_round_score()
{
	local RET_VAR=$1
    local ROUND_SUMMARY_FILE=$2
    while true; 
	do   # round loop
        # Shall we exit?
		EXIT_SIGNAL_FILE=`cat ${AIOCC_STATUS_SIGNAL_FILE}`
        if [ x"${EXIT_SIGNAL_FILE}" == x"${AIOCC_CTROL_STATUS_EXIT}" ]; then
            1>&2 echo "Exit signal file detected. Exiting..."
            exit 6
        fi

        local CANDIDATES_COUNT=`ls $CANDIDATES_DIR | wc -l`
        if [ $CANDIDATES_COUNT -eq 0 ]; then
            break
        fi
        local CANDIDATE=`ls $CANDIDATES_DIR | head -1`
        while true; do # candidate loop
            # benchmark_rule() puts ${VAR_PER},${CANDIDATE_TRY} into $1
            local S
            if ! benchmark_rule S $CANDIDATE $ROUND_SUMMARY_FILE; then
                if [ $FAILURES -gt 10 ]; then
                    1>&2 echo "Too many failures, aborting..."
                    exit 7
                fi
                continue
            fi
            local VAR_PER=`echo $S | cut -d, -f 1`
            local CANDIDATE_TRY=`echo $S | cut -d, -f 2`

            if [ $VAR_PER -le $VAR_PER_THRESHOLD ]; then
                1>&2 echo "VAR_PER is $VAR_PER, stable enough, proceeding to next rule"
                break
            elif [ $CANDIDATE_TRY -ge 3 ]; then
                1>&2 echo "CANDIDATE_TRY is $CANDIDATE_TRY, VAR_PER is $VAR_PER, giving up trying this rule, proceeding to next rule"
                break
            fi
            1>&2 echo "VAR_PER is $VAR_PER, too high, trying this rule one more time"
        done
        # we do nothing if the score line is missing from
        # ANALYSIS_FILE; that may be from a bad run
        rm "${CANDIDATES_DIR}/${CANDIDATE}"
    done

    # Re-run the top score rule if it's tried less than 3 times
    while true; do
        # get the round's best score line
        local SCORE_LINE=`${WORKLOAD_BIN_DIR}/get_highest_score.sh $ROUND_SUMMARY_FILE $MAX_BW`
        local NO_SCORE=`wc -l $ROUND_SUMMARY_FILE | awk '{print $1}'`
        local CANDIDATE=`echo $SCORE_LINE | cut -d, -f 1`
        local CANDIDATE_AVG_BW=`echo $SCORE_LINE | cut -d, -f 3`
        local CANDIDATE_AVG_VAR=`echo $SCORE_LINE | cut -d, -f 4`
        local CANDIDATE_TRY=`echo $SCORE_LINE | cut -d, -f 5`
        if [ $CANDIDATE_TRY -ge 3 -o $NO_SCORE -eq 1 ]; then
            eval "$RET_VAR=$SCORE_LINE"
            return
        fi

        1>&2 echo "Re-exam best round candidate $CANDIDATE"
        local S
        if ! benchmark_rule S $CANDIDATE $ROUND_SUMMARY_FILE; then
            if [ $FAILURES -gt 10 ]; then
                1>&2 echo "Too many failures, aborting..."
                exit 7
            fi
        fi
    done
}

#############################################################################################
#										开始AIOCC											
#############################################################################################
print_message "MULTEXU_INFO" "Now start AIOCC ..."
cd ${AIOCC_RULE_DATABASE_DIR}
__initialize
print_message "MULTEXU_INFO" "Entering directory ${AIOCC_RULE_DATABASE_DIR}..."
`${PAUSE_CMD}`
#
#参数意义：rule
#rule_num,rules_per_sec ack_ewma_lower,ack_ewma_upper,send_ewma_lower,send_ewma_upper,rtt_ratio100_lower,rtt_ratio100_upper,m100,b100,tau
#
if [ -f "${AIOCC_RULE_DATABASE_DIR}/epoch.cfg" ]; then
    EPOCH=`cat ${AIOCC_RULE_DATABASE_DIR}/epoch.cfg`
else
    EPOCH=0
    echo $EPOCH>${AIOCC_RULE_DATABASE_DIR}/epoch.cfg
    if [ ${INITIAL_RULE} -eq 0 ]; then
		:>${AIOCC_RULE_CANDIDATE_DIR}/0
        print_message "MULTEXU_INFO" "Starting Epoch 0 with default rule"
        if [ $ENABLE_M -eq 0 ]; then
            cat >${AIOCC_RULE_CANDIDATE_DIR}/0 <<EOF
1,2
0,${MAX_INT},0,${MAX_INT},0,${MAX_INT},-1,0,20000
EOF
        else
            cat >${AIOCC_RULE_CANDIDATE_DIR}/0 <<EOF
1,2
0,${MAX_INT},0,${MAX_INT},0,${MAX_INT},100,0,20000
EOF
        fi
    else
        print_message "MULTEXU_INFO" "Starting Epoch 0 with rule" $INITIAL_RULE
        cp ${AIOCC_RULE_DATABASE_DIR}/initial.rule ${AIOCC_RULE_CANDIDATE_DIR}/0
    fi
fi

EPOCH_RESULT_DIR=${AIOCC_RULE_DATABASE_DIR}/"epoch_${EPOCH}"
auto_mkdir ${EPOCH_RESULT_DIR} "weak" 


# main work loop
WORK_LOOP="cat ${AIOCC_CONFIG_DIR}/work_loop.cfg"
while [ x`$WORK_LOOP` == x"true" ] ; 
do
    EPOCH=`cat ${AIOCC_RULE_DATABASE_DIR}/epoch.cfg`
    EPOCH_RESULT_DIR=${AIOCC_RULE_DATABASE_DIR}/"epoch_${EPOCH}"
    auto_mkdir ${EPOCH_RESULT_DIR} "weak" 
    if [ -f ${EPOCH_RESULT_DIR}/round ]; then
        ROUND=`cat ${EPOCH_RESULT_DIR}/round`
    else
        ROUND=0
        echo $ROUND >${EPOCH_RESULT_DIR}/round
    fi
	MAX_BW_FILE=${EPOCH_RESULT_DIR}/realtime_max.bandwidth
    # run all candidates in this round and find the best round score
    ROUND_SUMMARY_FILE=${EPOCH_RESULT_DIR}/round_${ROUND}_summary.csv
	
    print_message "MULTEXU_INFO" "Running Epoch $EPOCH Round $ROUND"
	exit 0
    get_best_round_score ROUND_BEST_SCORE_LINE $ROUND_SUMMARY_FILE

    sh ${AIOCC_SEARCH_POLICY_DIR}/${SEARCH_POLICY}/next_round.sh "${ROUND_BEST_SCORE_LINE}"
done # epoch loop

#计算程序运行的时间
end_time=$(date +%s%N)
end_time_ms=${end_time:0:16}
#scale=6
time_cost=0
time_cost=`echo "scale=6;($end_time_ms - $start_time_ms)/1000000" | bc` 
print_message "MULTEXU_INFO" "AIOCC process finished..."
print_message "MULTEXU_INFO" "Total time spent:${time_cost} s"
