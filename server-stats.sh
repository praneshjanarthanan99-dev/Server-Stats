S#!/bin/bash
echo "======Server Stats Menu======"
echo ""
echo "Choose an Option"
echo ""
echo "1. Memory Usage"
echo ""
echo "2. Disk Usage"
echo ""
echo "3. CPU USage"
echo ""
echo "4. Top CPU Consuming Processes"
echo ""
echo "5. Top Memory Consuming Processes"
echo ""
echo "6. System Uptime"
echo ""
echo "7. Load Average"
echo ""
echo "8. OS Version"
echo ""
echo "9. Network Connectivity"
echo ""
echo "10. Exit"
echo "" 

while true; do
read -p "Choose an option: " choice 
echo ""

if [ "$choice" -eq 1 ]; then
  free -h

elif [ "$choice" -eq 2 ]; then
  df -h

elif [ "$choice" -eq 3 ]; then
  top -bn1 | grep "%Cpu"

elif [ "$choice" -eq 4 ]; then
  ps aux --sort=%cpu | head -n 6

elif [ "$choice" -eq 5 ]; then
  ps aux --sort=%mem | head -n 6

elif [ "$choice" -eq 6 ]; then
  uptime -p

elif [ "$choice" -eq 7 ]; then
  cat /proc/loadavg

elif [ "$choice" -eq 8 ]; then
  grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2

elif [ "$choice" -eq 9 ]; then
  ping -c 4 google.com

elif [ "$choice" -eq 10 ]; then
  echo " Existing Server Stats GoodBye"

  break

else
  echo " Invalid Option. Please choose 1 to 10"

fi
done
