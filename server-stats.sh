#!/bin/bash

echo ""
echo "=====SERVER-STATS====="

echo ""
echo "===MEMORY USAGE==="
free -h

echo ""
echo "===DISK USAGE==="
df -h

echo ""
echo "===CPU Consuming Processes==="
ps aux --sort=-%cpu | head -n 6

echo ""
echo "===Top 5 Processes by Memory==="
ps aux --sort=-%mem | head -n 6


echo ""
echo "====CPU USAGE==="

idle=$(top -bn1 | sed -n '3p' | awk -F',' '{print $4}' | awk '{print $1}')
echo "CPU Usage: $(bc <<< "100 - $idle")%"

echo ""
echo "===OS VERSION==="

echo "OS Version: $(grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2)"

echo ""
echo "===SYSTEM UPTIME==="
uptime -p

echo ""
echo "===LOAD AVERAGE==="
uptime | awk -F 'load average:' '{print $2}'
