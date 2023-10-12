#!/bin/bash
if [[ ${1} = "" || ${1} = "--help" || ${1} = "-h" ]];then 
	echo -ne "Usage: $0 [--scan | -s]\n"
	echo -ne "\n"
	exit
else
	case $1 in
		-s) echo -ne "Scanning for new disks, please wait...\n"
		    for h in $(ls /sys/class/scsi_host/); do echo "- - -" > /sys/class/scsi_host/${h}/scan;done
		    ;;
		--scan) echo -ne "Scanning for new disks, please wait...\n"
			for h in $(ls /sys/class/scsi_host/); do echo "- - -" > /sys/class/scsi_host/${h}/scan;done
			;;	
		*) echo -ne "Usage: $0 [--scan | -s]\n" 
		   echo -ne "\n"
		   exit
		   ;;
	esac	
fi
exit 0
