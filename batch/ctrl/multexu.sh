#
#description:    a simple unified management tool for multi-node scenario
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-07-19
#

#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f __init.sh ]; then
	echo "MULTEXU ERROR:multexu initialization failure:cannot find the file __init.sh... "
	exit 1
else
	source ./__init.sh
fi

# Reset all variables that might be set

iptable= #parameter format:xxx.out or 192.168.11.1,192,168,11,2 

declare -a ip_array
cmd_reboot=""
cmd_cmd=""  #the custom command


#
#检验ip地址是否合法,合法返回0 否则返回非0值
#
function is_valid_ip()
{
    local ip=$@
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return "$stat" 
}


#
#将配置文件中的ip或者用户给出的ip列表转换为数组形式存储在 [全局变量] ip_array中
#    如果给出的是配置文件，则到指定的配置文件中读取ip地址并存储在ip_array
#    如果是以 ip,ip,ip 形式给出ip地址，则分割处理ip并存储在ip_array中
#    注：两种情况均不校验合法性
#
function iptable_to_ip_array()
{
    local iptable_var=$1
    if [[ ${iptable_var} =~ ".out" ]]; then #给出ip配置文件的名称
        local index=0
        for ip_var in $(cat "${MULTEXU_BATCH_CONFIG_DIR}"/${iptable_var})
        do
            if [[ ${ip_var} ]]; then
                ip_array[index]=`echo ${ip_var} | sed s/[[:space:]]//g`
                let index++
            fi
        done
    else #另一种格式给出ip地址,进行分割处理
        iptable_var=`echo ${iptable_var} | sed s/[[:space:]]//g`
        OLD_IFS="$IFS" 
        IFS=","
        ip_array=($iptable_var)
        IFS="$OLD_IFS" 
    fi
}

#
#发送文件给指定的主机:文件名列表以逗号隔开,例如file1,file2,file3
#
function sendfiles()
{
    local filename_list=
    
    OLD_IFS="$IFS" 
    IFS=","
    local filename_list=($1)
    IFS="$OLD_IFS"
    shift 
    local file_savepath=$1
    shift    
    local ip_array_var=$@ #get ip set

    for filename_var in ${filename_list[@]}
    do
        for ip_var in ${ip_array_var[@]}
        do
            scp -o StrictHostKeyChecking=no -rp "${filename_var}" "root@${ip_var}:${file_savepath}"
        done #ip_var
    done #filename_var
}

#
#检验给定ip数组中是否有不合法的ip地址，有不合法的ip返回1，全部合法返回0
#
function check_ip_array()
{
    local ip_array_var=$@
    for ip_var in ${ip_array_var[@]}
    do
        is_valid_ip "$ip_var"
        retval=$?
        if [[ "$retval" -ne 0 ]]; then
        return 1
    fi
    done
    return 0
}


#
#命令参数列表：[命令] [ip_array]
#对ip_array中存储的所有主机执行给定命令
#
function execute_sshcmd()
{
    local cmd_str=$1;
    shift
    local iptable_array_var=$@;
    for ip_var in ${iptable_array_var[@]}
    do      
        ssh -f ${ip_var} "${cmd_str}"
    done
}

#
#显示版本号 
#
function show_version()
{
    echo "MULTEXU INFO:multexu 1.0 DSAL,WNLO"
}    
     
#
#显示帮助文档
#
function show_help()
{
    cat help_doc.txt >&2     
}

#
#接受参数，调用相应函数执行
#
function get_parameters()
{
    local filenames=""  #文件名称，以逗号隔开
    local location=""  #文件保存位置
    while :; do
        case $1 in
        -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
            show_help
            exit
            ;;
        -l=?*|--location=?*)       # Takes an option argument, ensuring it has been specified.
            location=${1#*=} # Delete everything up to "=" and assign the remainder.
            shift
            ;;
        -l=*|--location=*)         # Handle the case of an empty -l=|--location=
            printf 'MULTEXU ERROR: "-s|--sendfile" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        -s=?*|--sendfile=?*)       # Takes an option argument, ensuring it has been specified.
            filenames=${1#*=} # Delete everything up to "=" and assign the remainder.
            shift
            ;;
        -s|--sendfile=)         # Handle the case of an empty --file=
            printf 'MULTEXU ERROR: "-s|--sendfile" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        -u|--udefine)       # Takes an option argument, ensuring it has been specified.
            if [ -n "$2" ]; then
                undefine=$2
                shift
            else
                printf 'MULTEXU ERROR: "-u|--undefine" requires a non-empty option argument.\n' >&2
                exit 1
            fi
            ;;
        --supercmd=?*)  #the most complex command,when this parameter is used , it must be as the last parameter
            cmd_cmd=${@#*--supercmd=}
            break
            ;;
        -c=?*|--cmd=?*)
            cmd_cmd=${1#*=} # Delete everything up to "=" and assign the remainder.
            shift
            while [[ ! $1 =~ -{1,2}[a-zA-Z]+=[a-zA-Z]+ ]] && [ $1 ];
            do
                cmd_cmd="${cmd_cmd} $1"
                shift
            done
            ;;
        -c|--cmd=)         # Handle the case of an empty --file=
            printf 'MULTEXU ERROR: "-c|--cmd" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        -i=?*|--iptable=?*)
            iptable=${1#*=} # Delete everything up to "=" and assign the remainder.
            shift
            ;;
        -i=|--iptable=)         # Handle the case of an empty --file=
            printf 'MULTEXU ERROR: "--iptable" requires a non-empty option argument.\n' >&2
            exit 1
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -r|--reboot)
            cmd_reboot=$((verbose + 1)) # reboot
            shift
            ;;
        --)              # End of all options.
            shift
            ;;
        -?*)
            printf 'MULTEXU WARN: Unknown option (ignored): %s\n' "$1" >&2
            shift
            ;;
        *)               # Default case: If no more options then break out of the loop.
            shift
            break
        esac
    done

    # if --iptable was provided, check it for its legality
    if [ -n "$iptable" ]; then
        iptable_to_ip_array "$iptable"
        check_ip_array "${ip_array[@]}"
            retval=$?
            if [[ "$retval" -ne 0 ]]; then
                echo 'MULTEXU ERROR:the parameter iptable string contains illegal ip address...'
                exit 1
            fi
    else #the parameter iptables must be given
        echo "MULTEXU ERROR:the parameter iptable is necessary..."
    fi
    #command must be given
    if [ ! -n "${cmd_reboot}" ] && [ ! -n "${cmd_cmd}" ] && [ ! -n "${filenames}" ]; then
        echo "MULTEXU ERROR:the command is necessary..."
        exit 1
    fi    

    if [[ -n "$cmd_reboot" ]]; then
        execute_sshcmd "reboot" "${ip_array[@]}" 
    elif [[ -n "$cmd_cmd" ]]; then
        execute_sshcmd "${cmd_cmd}" "${ip_array[@]}"
    fi
    if [ -n "$filenames" ]; then
        if [ ! -n "${location}" ]; then
            echo "MULTEXU ERROR:destination location is necessary..."
            exit 1
        fi
        sendfiles "${filenames}" "${location}" "${ip_array[@]}"
    fi    
}

#####################

get_parameters $@

###reset
ip_array=
cmd_reboot=""
cmd_cmd="" #the custom command
exit 0
