 #!/bin/bash
# POSIX
#
#description:    install pip
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2017-01-11
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
#install setuptools-32
unzip -o setuptools-32.3.1.zip 
cd setuptools-32.3.1/
python easy_install.py 
wait
python setup.py buil
wait
python setup.py install
wait
cd ../
#install pip
tar -xvf pip-9.0.1.tar.gz 
cd pip-9.0.1/
python setup.py install

ln -s /usr/local/python3.5.2/bin/pip /usr/bin/pip

print_message "MULTEXU_INFO" "Leaving directory ${MULTEXU_SOURCE_TOOL_DIR}..."
print_message "MULTEXU_INFO" "finished to install pip..."
