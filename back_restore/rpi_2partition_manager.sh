#!/bin/bash
myAppName=rpi_2partition_manager

#All args are read from command line!
#export RPI_DEVICE=/dev/sdc
#export BACKUP_PATH=/media/cezar/Arhiva/PI/20160000
#export RUN_MODE=restore
#export RUN_MODE=backup
#export DRY_RUN="true"
#export RPI_NAME=rpi_jessie
doQualifiedDeviceName () 
{
	if [ $RPI_DEVICE_MODE = "/dev/sd" ]; then
		echo "$RPI_DEVICE"$1
	elif [ $RPI_DEVICE_MODE = "/dev/mmcblk" ]; then
		echo "$RPI_DEVICE"p$1
	fi
}
doCommand () {
	if [ $DRY_RUN = "true" ]; then
		echo "DRY_RUN: $@"
	else
		echo "REAL_RUN: $@"
		if [ $1 = "fdisk" ]; then
			echo "BACKUP_PATH_MODE is $BACKUP_PATH_MODE"
			if [ "$BACKUP_PATH_MODE" = "ssh://" -o "$BACKUP_PATH_MODE" = "ssh+zip://" ]; then
				echo "Doing LS on ssh destination"
				echo $RPI_NAME > sudofdisk-l_$RPI_NAME.txt
				echo "username $USERNAME" >> sudofdisk-l_$RPI_NAME.txt
				echo "password $PASSWORD" >> sudofdisk-l_$RPI_NAME.txt
				echo "sudo ./$myAppName.sh device null backup_path $BACKUP_PATH_MODE$BACKUP_PATH run_mode restore name $RPI_NAME dry-run true" >> sudofdisk-l_$RPI_NAME.txt 
				$@ >> sudofdisk-l_$RPI_NAME.txt
				eval "cat sudofdisk-l_$RPI_NAME.txt | ssh $USER@$SERVER -p $PORT \"cat > $BACKUP_PATH_SSH_PREFIX/sudofdisk-l_$RPI_NAME.txt\""
				rm sudofdisk-l_$RPI_NAME.txt;
			else
				echo $RPI_NAME > $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt
				echo "username $USERNAME" >> $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt
				echo "password $PASSWORD" >> $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt
				echo "sudo ./$myAppName.sh device null backup_path $BACKUP_PATH run_mode restore name $RPI_NAME dry-run true" >> $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt 
				$@ >> $BACKUP_PATH/sudofdisk-l_$RPI_NAME.txt;
			fi
			
		else
			eval $@;					
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
	echo "Example ./$myAppName.sh device /dev/sdc backup_path /media/cezar/Arhiva/PI/20160000 run_mode backup name rpi dry-run true username cezar password 12345"
	exit ;
else
	echo "Checking args.."

	while [ $# -ne 0 ]
	  do
		#echo "Current Parameter: $1 , Remaining $#"
		if [ "$1" = "device" ]; then
			RPI_DEVICE=$2
			RPI_DEVICE_MODE="unknown"
			if [ ${RPI_DEVICE::-1} = "/dev/sd" ]; then
				RPI_DEVICE_MODE=${RPI_DEVICE::-1}
			elif [ ${RPI_DEVICE::-1} = "/dev/mmcblk" ]; then
				RPI_DEVICE_MODE=${RPI_DEVICE::-1}
			fi
			echo "Device mode is $RPI_DEVICE_MODE"
		elif [ "$1" = "backup_path" ]; then
			BACKUP_PATH_MODE="unknown"
			BACKUP_PATH=$2
			if [ ${BACKUP_PATH:0:6} = "ssh://" ]; then
				BACKUP_PATH_MODE="ssh://"
			elif [ ${BACKUP_PATH:0:10} = "ssh+zip://" ]; then
                                BACKUP_PATH_MODE="ssh+zip://"
			else
				BACKUP_PATH_MODE="fs"
                        fi
			echo "BACKUP_PATH_MODE is $BACKUP_PATH_MODE"
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
if [ "$RPI_DEVICE_MODE" = "unknown" ]; then
	echo "Device mode cannot be handled"
	exit ;
fi
if [ -z ${BACKUP_PATH+x} ]; then 
	echo "BACKUP_PATH is unset"
	exit ; 
else 
	echo "BACKUP_PATH is set to '$BACKUP_PATH'"; 
	
fi
if [ "$BACKUP_PATH_MODE" = "unknown" ]; then
	echo "Backup path cannot be handled"
	exit ;
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

qualifiedDeviceName=""
qualifiedDeviceName=$(doQualifiedDeviceName $myPartition)
myCommand="umount $qualifiedDeviceName"
doCommand $myCommand
myPartition=2
qualifiedDeviceName=$(doQualifiedDeviceName $myPartition)
myCommand="umount $qualifiedDeviceName"
doCommand $myCommand
if [ "$BACKUP_PATH_MODE" = "ssh://" -o "$BACKUP_PATH_MODE" = "ssh+zip://" ]; then
        if [ "$BACKUP_PATH_MODE" = "ssh://" ]; then
		BACKUP_PATH=${BACKUP_PATH:6:${#BACKUP_PATH}}
	elif [ "$BACKUP_PATH_MODE" = "ssh+zip://"  ]; then
		BACKUP_PATH=${BACKUP_PATH:10:${#BACKUP_PATH}}
	fi
        IFS='@' read USER ADDR2 <<<$BACKUP_PATH
        IFS=':' read SERVER ADDR2 <<<$ADDR2
        IFS='/' read PORT ADDR2 <<<$ADDR2
	BACKUP_PATH_SSH_PREFIX="/$ADDR2/"
fi
if [ $RUN_MODE = "restore" ]; then
	myPartition=1
	mySuffix="_head"
	qualifiedDeviceName=$(doQualifiedDeviceName $myPartition) 
	if [ "$BACKUP_PATH_MODE" = "ssh://" ]; then
		BACKUP_PATH="$BACKUP_PATH_SSH_PREFIX$RPI_NAME$mySuffix.img"	
		myCommand="ssh $USER@$SERVER -p $PORT \"cat $BACKUP_PATH\" | pv | sudo dd of=$qualifiedDeviceName"
	elif [ "$BACKUP_PATH_MODE" = "ssh+zip://" ]; then
                BACKUP_PATH="$BACKUP_PATH_SSH_PREFIX$RPI_NAME$mySuffix.img.gz"
                myCommand="ssh $USER@$SERVER -p $PORT \"cat $BACKUP_PATH | gunzip\" | pv | sudo dd of=$qualifiedDeviceName"
	else
		myCommand="dd if=$BACKUP_PATH/$RPI_NAME$mySuffix.img of=$qualifiedDeviceName"
	fi
	doCommand $myCommand
	myPartition=2
	mySuffix="_main"
	qualifiedDeviceName=$(doQualifiedDeviceName $myPartition)
	if [ "$BACKUP_PATH_MODE" = "ssh://" ]; then
		BACKUP_PATH="$BACKUP_PATH_SSH_PREFIX$RPI_NAME$mySuffix.ext4"
		myCommand="ssh $USER@$SERVER -p $PORT \"cat $BACKUP_PATH\" | sudo partclone.ext4 -r -d -o $qualifiedDeviceName"
	elif [ "$BACKUP_PATH_MODE" = "ssh+zip://" ]; then
                BACKUP_PATH="$BACKUP_PATH_SSH_PREFIX$RPI_NAME$mySuffix.ext4.gz"
                myCommand="ssh $USER@$SERVER -p $PORT \"cat $BACKUP_PATH | gunzip\" | sudo partclone.ext4 -r -d -o $qualifiedDeviceName"
	else
		myCommand="partclone.ext4 -r -d -s $BACKUP_PATH/$RPI_NAME$mySuffix.ext4 -o $qualifiedDeviceName"
	fi
	doCommand $myCommand;

elif [ $RUN_MODE = "backup" ]; then
	if [ $DRY_RUN = "false" ]; then
		if [ "$BACKUP_PATH_MODE" = "ssh://" -o "$BACKUP_PATH_MODE" = "ssh+zip://" ]; then
			echo "Checking remote directory exits.."
			myCommand="ssh $USER@$SERVER -p $PORT \"mkdir $BACKUP_PATH_SSH_PREFIX\""
			doCommand $myCommand;
		else
			if [ -e $BACKUP_PATH ]; then 
				echo "Backup path exists";
			else
				echo "Backup path doesn't exist, creating";
				mkdir $BACKUP_PATH
			fi;
		fi
	fi
	myCommand="fdisk -l $RPI_DEVICE"
	doCommand $myCommand 
	myPartition=1
	mySuffix="_head"
	qualifiedDeviceName=$(doQualifiedDeviceName $myPartition) 
	if [ "$BACKUP_PATH_MODE" = "ssh://" ]; then
		BACKUP_PATH="$BACKUP_PATH_SSH_PREFIX$RPI_NAME$mySuffix.img"
		myCommand="USER is $USER Server is $SERVER Port is $PORT Backup_path is $BACKUP_PATH"
		myCommand="dd if=$qualifiedDeviceName | pv | ssh $USER@$SERVER -p $PORT \"cat | dd of=$BACKUP_PATH\""
	elif [ "$BACKUP_PATH_MODE" = "ssh+zip://" ]; then
                BACKUP_PATH="$BACKUP_PATH_SSH_PREFIX$RPI_NAME$mySuffix.img.gz"
                myCommand="USER is $USER Server is $SERVER Port is $PORT Backup_path is $BACKUP_PATH"
                myCommand="dd if=$qualifiedDeviceName | pv | ssh $USER@$SERVER -p $PORT \"cat | gzip | dd of=$BACKUP_PATH\""
	else
		myCommand="dd of=$BACKUP_PATH/$RPI_NAME$mySuffix.img if=$qualifiedDeviceName"
	fi
	doCommand $myCommand
	myPartition=2
	qualifiedDeviceName=$(doQualifiedDeviceName $myPartition) 
	mySuffix="_main"
	if [ "$BACKUP_PATH_MODE" = "ssh://" ]; then
		BACKUP_PATH="$BACKUP_PATH_SSH_PREFIX$RPI_NAME$mySuffix.ext4"
		myCommand="partclone.ext4 -c -d -s $qualifiedDeviceName | ssh $USER@$SERVER -p $PORT \"cat > $BACKUP_PATH\""
	elif [ "$BACKUP_PATH_MODE" = "ssh+zip://" ]; then
                BACKUP_PATH="$BACKUP_PATH_SSH_PREFIX$RPI_NAME$mySuffix.ext4.gz"
                myCommand="partclone.ext4 -c -d -s $qualifiedDeviceName | ssh $USER@$SERVER -p $PORT \"cat | gzip > $BACKUP_PATH\""
	else
		myCommand="partclone.ext4 -c -d -s $qualifiedDeviceName -o $BACKUP_PATH/$RPI_NAME$mySuffix.ext4"
	fi
	doCommand $myCommand;
fi



