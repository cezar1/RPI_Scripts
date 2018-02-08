#!/bin/bash
#Insert following command before the end of /etc/rc.local
#sudo -u pi bash /home/pi/restore_wifi.sh &
while true ; do
   if ifconfig wlan0 | grep -q "inet" ; then
      sleep 60
   else
      echo "Network connection down! Attempting reconnection."
      ifup --force wlan0
      sleep 10
   fi
done
