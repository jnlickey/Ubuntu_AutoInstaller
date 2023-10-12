#!/bin/bash
# Run this script without any param for a dry run
# Run the script with root and with exec param for removing old kernels after checking
# the list printed in the dry run

if [[ ${1} = "" || ${1} = "-h" || ${1} = "--help" ]];then
    echo -ne "Usage: $0 <exec>\n    exec - Will execute the removal of all old kernels\n"
    exit
fi

# Colors
GRN="\033[1;32m"
YEL="\033[93m"
NC="\033[0m"

uname -a
IN_USE=$(uname -a | awk '{ print $3 }')
echo -e "${YEL}Kernel in use is:${NC} ${GRN}${IN_USE}${NC}"

OLD_KERNELS=$(
    dpkg --list |
        grep -v "$IN_USE" |
        grep -Ei 'linux-image|linux-headers|linux-modules' |
        awk '{ print $2 }'
)
echo -ne "\nOld Kernels to be removed:\n"
echo "$OLD_KERNELS"

if [ "$1" == "exec" ]; then
    for PACKAGE in $OLD_KERNELS; do
        yes | apt purge "$PACKAGE"
    done
fi
