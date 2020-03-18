#!/bin/bash
while true
do
	echo $(date)
	vcgencmd get_throttled
	vcgencmd measure_temp
	vcgencmd measure_clock arm
	sleep 5
done	
