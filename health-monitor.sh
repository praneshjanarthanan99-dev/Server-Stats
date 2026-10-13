#!/bin/bash

# Smart Server Health Checker
# Version 1.0

VERSION="1.0"

echo "================================"
echo "   SMART SERVER HEALTH CHECKER"
echo "================================"
echo "Version: $VERSION"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "================================"

# DISK HEALTH
echo ""
echo "-------- DISK HEALTH --------"

disk_usage=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')

if [ -z "$disk_usage" ]; then
    echo "ERROR: Unable to read disk usage."
elif [ "$disk_usage" -ge 90 ]; then
    echo "Disk usage: ${disk_usage}%"
    echo "CRITICAL: Disk space is almost full!"
elif [ "$disk_usage" -ge 75 ]; then
    echo "Disk usage: ${disk_usage}%"
    echo "WARNING: Disk usage is getting high."
else
    echo "Disk usage: ${disk_usage}%"
    echo "OK: Disk usage is normal."
fi

# MEMORY HEALTH
echo ""
echo "------- MEMORY HEALTH -------"

memory_usage=$(free | awk '/^Mem:/ {printf "%.0f", ($3/$2)*100}')

if [ -z "$memory_usage" ]; then
    echo "ERROR: Unable to read memory usage."
elif [ "$memory_usage" -ge 90 ]; then
    echo "Memory usage: ${memory_usage}%"
    echo "CRITICAL: Memory usage is very high!"
elif [ "$memory_usage" -ge 75 ]; then
    echo "Memory usage: ${memory_usage}%"
    echo "WARNING: Memory usage is getting high."
else
    echo "Memory usage: ${memory_usage}%"
    echo "OK: Memory usage is normal."
fi

# CPU HEALTH
echo ""
echo "-------- CPU HEALTH --------"

cpu_idle=$(top -bn1 | grep '%Cpu(s)' | awk -F',' '{print $4}' | awk '{print $1}')

if [ -z "$cpu_idle" ]; then
    echo "ERROR: Unable to read CPU usage."
else
    cpu_usage=$(awk -v idle="$cpu_idle" 'BEGIN {printf "%.0f", 100-idle}')

    echo "CPU usage: ${cpu_usage}%"

    if [ "$cpu_usage" -ge 90 ]; then
        echo "CRITICAL: CPU usage is very high!"
    elif [ "$cpu_usage" -ge 75 ]; then
        echo "WARNING: CPU usage is getting high."
    else
        echo "OK: CPU usage is normal."
    fi
fi

#PROCESS HEALTH
echo ""
echo "----------PROCESS HEALTH--------"

ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6

# OS INFORMATION
echo ""
echo "---------OS VERSION--------"

grep '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f 2

# SERVER UPTIME
echo ""
echo "------- SERVER UPTIME -------"

uptime -p

# NETWORK CONNECTIVITY
echo ""
echo "--------- NETWORK CONNECTIVITY ---------"

if ping -c 4 -w 2 8.8.8.8 > /dev/null 2>&1; then
  echo " Network Status: CONNECTED"

else
  echo " Network Status: Disconnected"
fi
