#!/bin/bash
#Insert following command before the end of /etc/rc.local
#sudo -u pi bash /home/pi/restore_wifi.sh &
while true ; do
   if ifconfig wlan0 | grep -q "inet" ; then
      sleep 60
   else
      echo "Network connection down! Attempting reconnection."
      ifup --force wlan0
      sudo ip link set wlan0 down
      sleep 5
      sudo ip link set wlan0 up
      sleep 10
   fi
done
