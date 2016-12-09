#!/bin/bash
# POSIX
#
#description:    install molokai automatically
#     author:    ShijunDeng
#      email:    dengshijun1992@gmail.com
#       time:    2016-08-15
#
#initialization
cd "$( dirname "${BASH_SOURCE[0]}" )" #get  a Bash script tell what directory it's stored in
if [ ! -f ../ctrl/__init.sh ]; then
    echo "MULTEXU Error:multexu initialization failure:cannot find the file __init.sh... "
    exit 1
else
    source ../ctrl/__init.sh
fi

source "${MULTEXU_BATCH_CRTL_DIR}"/multexu_lib.sh #调入multexu库
    
# Reset all variables that might be set
yum -y install vim
molokai_gitaddr='fihttps://github.com/tomasr/molokai.git'
MOLOKAI_DIR="molokai"
echo "MULTEXU INFO: install molokai automatically..."
`${PAUSE_CMD}`

cd ${MULTEXU_SOURCE_DIR}
echo "MULTEXU INFO:enter the directory ${MULTEXU_SOURCE_DIR}"
git clone ${molokai_gitaddr}
wait

cp ${MOLOKAI_DIR}/colors/molokai.vim /usr/share/vim/vim74/colors/

vim ~/.vimrc
echo "set t_Co=256" > ~/.vimrc
echo "colorscheme molokai" >> ~/.vimrc
echo "let g:rehash256 = 1" >> ~/.vimrc
echo "MULTEXU INFO:finished to install molokai..."
