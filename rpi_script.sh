#!/bin/bash
myAppName=rpi_script

#All args are read from command line!
#export RPI_DEVICE=/dev/sdc
#export BACKUP_PATH=/media/cezar/Arhiva/PI/20160000
#export RUN_MODE=restore
#export RUN_MODE=backup
#export DRY_RUN="true"
#export RPI_NAME=rpi_jessie

doCommand () {
	if [ $DRY_RUN = "true" ]; then
		echo "DRY_RUN: $@"
	else
		echo "REAL_RUN: $@"
		if [ $1 = "fdisk" ]; then
			echo $RPI_NAME > $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt
			echo "username $USERNAME" >> $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt
			echo "password $PASSWORD" >> $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt
			$@ >> $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt;
			
		else
			$@;					
		fi
	fi
}



echo "RPI utility script"

if [ "$#" -lt "8" -o "$1" = "help" ]; then
	echo "At least five arguments pairs are required. Usage <$myAppName [device] [backup_path] [run_mode] [name] [dry-run] [password]>" 
	echo "device = /dev/sdx"
	echo "backup_path = /media/cezar/Arhiva/PI/20160000"
	echo "run_mode = restore / backup" 
	echo "name = rpi2_jessie_minimal"
 	echo "dry-run = true / false"
	echo "username = myUsername"
	echo "password = 12345"
	echo "Example ./$myAppName device /dev/sdc backup_path /media/cezar/Arhiva/PI/20160000 run_mode backup name rpi dry-run true username cezar password 12345"
	exit ;
else
	echo "Checking args.."

	while [ $# -ne 0 ]
	  do
		#echo "Current Parameter: $1 , Remaining $#"
		if [ "$1" = "device" ]; then
			RPI_DEVICE=$2
		elif [ "$1" = "backup_path" ]; then
			BACKUP_PATH=$2
		elif [ "$1" = "run_mode" ]; then
			RUN_MODE=$2
		elif [ "$1" = "name" ]; then
			RPI_NAME=$2
		elif [ "$1" = "dry-run" ]; then
			DRY_RUN=$2
		elif [ "$1" = "username" ]; then
			USERNAME=$2
		elif [ "$1" = "password" ]; then
			PASSWORD=$2
		fi
		shift
		shift
	done
fi

if [ -z ${RPI_DEVICE+x} ]; then 
	echo "RPI_DEVICE is unset" 
	exit ; 
else 
	echo "RPI_DEVICE is set to '$RPI_DEVICE'"; 
fi
if [ -z ${BACKUP_PATH+x} ]; then 
	echo "BACKUP_PATH is unset"
	exit ; 
else 
	echo "BACKUP_PATH is set to '$BACKUP_PATH'"; 
fi
if [ -z ${RUN_MODE+x} ]; then 
	echo "RUN_MODE is unset"
	exit ; 
else 
	echo "RUN_MODE is set to '$RUN_MODE'"; 
fi
if [ -z ${DRY_RUN+x} ]; then 
	echo "DRY_RUN is unset"
	exit ; 
else 
	echo "DRY_RUN is set to '$DRY_RUN'"; 
fi
if [ -z ${RPI_NAME+x} ]; then 
	echo "RPI_NAME is unset"
	exit ; 
else 
	echo "RPI_NAME is set to '$RPI_NAME'"; 
fi

if [ $RUN_MODE = "restore" ]; then
	echo "Restore mode selected";
elif [ $RUN_MODE = "backup" ]; then
	echo "Backup mode selected";
else
	echo "Unknown mode <<$RUN_MODE>> selected"
	exit;
fi
if [ $DRY_RUN = "true" ]; then
	echo "DRY_RUN mode selected";
elif [ $DRY_RUN = "false" ]; then
	echo "REAL_RUN mode selected";
	if [ "$EUID" -ne 0 ]
	  then echo "Please run as root"
	  exit
	fi
else
	echo "Invalid DRY_RUN flag <<$DRY_RUN>> selected"
	exit;
fi
echo "Doing <<$RUN_MODE>> job on $RPI_DEVICE with name $RPI_NAME with path set to $BACKUP_PATH flag DRY_RUN <<$DRY_RUN>>.."
#First unmount device partitions
myPartition=1
myCommand="umount $RPI_DEVICE$myPartition"
doCommand $myCommand
myPartition=2
myCommand="umount $RPI_DEVICE$myPartition"
doCommand $myCommand

if [ $RUN_MODE = "restore" ]; then
	myPartition=1
	mySuffix="_head"
	myCommand="dd if=$BACKUP_PATH/$RPI_NAME$mySuffix.img of=$RPI_DEVICE$myPartition"
	doCommand $myCommand
	myPartition=2
	mySuffix="_main"
	myCommand="partclone.ext4 -r -d -s $BACKUP_PATH/$RPI_NAME$mySuffix.ext4 -o $RPI_DEVICE$myPartition"
	doCommand $myCommand;
elif [ $RUN_MODE = "backup" ]; then
	if [ $DRY_RUN = "false" ]; then
		if [ -e $BACKUP_PATH ]; then 
			echo "Backup path exists";
		else
			echo "Backup path doesn't exist, creating";
			mkdir $BACKUP_PATH
		fi;
	fi
	myCommand="fdisk -l $RPI_DEVICE"
	doCommand $myCommand 
	myPartition=1
	mySuffix="_head"
	myCommand="dd of=$BACKUP_PATH/$RPI_NAME$mySuffix.img if=$RPI_DEVICE$myPartition"
	doCommand $myCommand
	myPartition=2
	mySuffix="_main"
	myCommand="partclone.ext4 -c -d -s $RPI_DEVICE$myPartition -o $BACKUP_PATH/$RPI_NAME$mySuffix.ext4"
	doCommand $myCommand;
fi
#Backup
#sudo dd of=/media/cezar/Arhiva/PI/20160304/rpi3_jessie_head.img if=/dev/sdc1
#sudo partclone.ext4 -c -d -s /dev/sdc2 -o /media/cezar/Arhiva/PI/20160304/rpi3_jessie_main.ext4

#Restore
#sudo dd if=/media/cezar/Arhiva/PI/20160304/rpi3_jessie_head.img of=/dev/sdc1
#sudo partclone.ext4 -r -d -s /media/cezar/Arhiva/PI/20160304/rpi3_jessie_main.ext4 -o /dev/sdc2



