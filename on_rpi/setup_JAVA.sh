#!/bin/bash
DIRECTORY="/usr/java"
DRY_RUN="true"
HELPER_FILE=".bash_setup_java"
APP="setup_java.sh"
TARGET_RC="~/.bashrc"
doCommandHelper () {
	if [ $DRY_RUN = "true" ]; then
		echo "DRY_RUN: $@"
	else
		echo "REAL_RUN: $@"
		echo "$@" >> $HELPER_FILE;
	fi
}
doCommandShell () {
	if [ $DRY_RUN = "true" ]; then
		echo "DRY_RUN: $@"
	else
		echo "REAL_RUN: $@"
		eval $@;
	fi
}
echo "JAVA Setup script. This script looks up into $DIRECTORY for java jdk folders, then creates a helper file $HELPER_FILE which is copied to ~. Please check the contents of $TARGET_RC file before running the script!"
echo "By default, script will be executed in DRY_RUN mode. To execute in REAL_RUN mode, please add argument 1 after the script, ie [ ./$APP 1 ]"
if [ $# -eq 0 ]; then
	echo "Running script in DRY_RUN.."
else
	echo "Running script in REAL_RUN.."
	DRY_RUN="false"
fi
if [ -d "$DIRECTORY" ]; then
	if [ ${#DIRECTORY[@]} -gt 0 ]; then 
		echo "Found at least one file/folder in $DIRECTORY"; 
	else
		echo "$DIRECTORY exists, but is empty, extract some jdks in it!"
		exit;
	fi
	# Control will enter here if $DIRECTORY exists.
	echo "Listing contents of $DIRECTORY into $HELPER_FILE"
	rm $HELPER_FILE
	echo "#$DIRECTORY hooks into environment" > $HELPER_FILE
	for n in $DIRECTORY/*; 
		#do echo "$n";
		do myCommand="export myJAVA=$n";
		doCommandHelper $myCommand; 
	done
	myCommand="export JAVA_HOME=\$myJAVA/bin/java";
	doCommandHelper $myCommand; 
	myCommand="export PATH=\$PATH:\$myJAVA/bin";
	doCommandHelper $myCommand; 
	myCommand="rm ~/$HELPER_FILE";
	doCommandShell $myCommand; 
	myCommand="mv $HELPER_FILE ~/$HELPER_FILE";
	doCommandShell $myCommand; 
	myCommand="echo 'source ~/$HELPER_FILE' >> $TARGET_RC";
	doCommandShell $myCommand; 
else
	#Directory doesn't exist, exit with error message
	echo "Please extract jdks under folder $DIRECTORY!"
	exit ;
fi
