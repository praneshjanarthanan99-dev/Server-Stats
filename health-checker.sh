#!/bin/bash

# Smart Server Health Checker
# Version 1.0

VERSION="1.0"

show_header() {
    echo "================================"
    echo "   SMART SERVER HEALTH CHECKER"
    echo "================================"
    echo "Version: $VERSION"
    echo "Hostname: $(hostname)"
    echo "Date: $(date)"
    echo "================================"
}

check_disk() {
    echo ""
    echo "-------- DISK HEALTH --------"

    local disk_usage
    disk_usage=$(df -P / 2>/dev/null | awk 'NR==2 {gsub("%", "", $5); print $5}')

    if ! [[ "$disk_usage" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Unable to read disk usage." >&2
        return 1
    fi

    echo "Disk usage: ${disk_usage}%"
    if (( disk_usage >= 90 )); then
        echo "CRITICAL: Disk space is almost full!"
    elif (( disk_usage >= 75 )); then
        echo "WARNING: Disk usage is getting high."
    else
        echo "OK: Disk usage is normal."
    fi
}

check_memory() {
    echo ""
    echo "-------- MEMORY HEALTH --------"

    local memory_usage
    memory_usage=$(free 2>/dev/null | awk '/^Mem:/ {if ($2 > 0) printf "%.0f", ($3/$2)*100}')

    if ! [[ "$memory_usage" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Unable to read memory usage." >&2
        return 1
    fi

    echo "Memory usage: ${memory_usage}%"
    if (( memory_usage >= 90 )); then
        echo "CRITICAL: Memory usage is very high!"
    elif (( memory_usage >= 75 )); then
        echo "WARNING: Memory usage is getting high."
    else
        echo "OK: Memory usage is normal."
    fi
}

get_cpu_usage() {
    local cpu_idle
    cpu_idle=$(LC_ALL=C top -bn1 2>/dev/null | awk -F',' '/Cpu\(s\)/ {for (i=1; i<=NF; i++) if ($i ~ /id/) {gsub(/[^0-9.]/, "", $i); print $i; exit}}')

    if ! [[ "$cpu_idle" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        return 1
    fi

    awk -v idle="$cpu_idle" 'BEGIN {usage=100-idle; if (usage<0) usage=0; if (usage>100) usage=100; printf "%.0f", usage}'
}

check_cpu() {
    echo ""
    echo "-------- CPU HEALTH --------"

    local cpu_usage
    cpu_usage=$(get_cpu_usage) || {
        echo "ERROR: Unable to read CPU usage." >&2
        return 1
    }

    echo "CPU usage: ${cpu_usage}%"
    if (( cpu_usage >= 90 )); then
        echo "CRITICAL: CPU usage is very high!"
    elif (( cpu_usage >= 75 )); then
        echo "WARNING: CPU usage is getting high."
    else
        echo "OK: CPU usage is normal."
    fi
}

show_cpu_graph() {
    echo ""
    echo "-------- CPU USAGE GRAPH --------"

    local cpu_usage bar graph="" i
    cpu_usage=$(get_cpu_usage) || {
        echo "ERROR: Unable to read CPU usage." >&2
        return 1
    }

    bar=$((cpu_usage / 5))
    for ((i=0; i<bar; i++)); do graph+="#"; done
    for ((i=bar; i<20; i++)); do graph+="-"; done

    echo "CPU usage: ${cpu_usage}%"
    echo "[$graph]"
    echo "Each # represents approximately 5% CPU usage."
}

show_top_cpu() {
    echo ""
    echo "-------- TOP CPU-CONSUMING PROCESSES --------"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6 || {
        echo "ERROR: Unable to list CPU processes." >&2
        return 1
    }
}

show_top_memory() {
    echo ""
    echo "-------- TOP MEMORY-CONSUMING PROCESSES --------"
    ps -eo pid,comm,%mem --sort=-%mem | head -n 6 || {
        echo "ERROR: Unable to list memory processes." >&2
        return 1
    }
}

show_uptime() {
    echo ""
    echo "-------- SERVER UPTIME --------"
    uptime -p || {
        echo "ERROR: Unable to read server uptime." >&2
        return 1
    }
}

show_load_average() {
    echo ""
    echo "-------- LOAD AVERAGE --------"
    if [[ -r /proc/loadavg ]]; then
        awk '{print "1 minute: " $1 " | 5 minutes: " $2 " | 15 minutes: " $3}' /proc/loadavg
    else
        echo "ERROR: Unable to read load average." >&2
        return 1
    fi
}

show_os_version() {
    echo ""
    echo "-------- OS VERSION --------"
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        echo "${PRETTY_NAME:-Unknown Linux distribution}"
    else
        echo "ERROR: Unable to read OS version." >&2
        return 1
    fi
}

check_network() {
    echo ""
    echo "-------- NETWORK CONNECTIVITY --------"
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo "Network status: CONNECTED"
    else
        echo "ERROR: Network connectivity check failed. The server may be offline or ping may be blocked." >&2
        return 1
    fi
}

show_help() {
    cat <<'HELP'

SMART SERVER HEALTH CHECKER - HELP

Run without flags to open the interactive menu:
  ./health-monitor.sh

Available flags:
  --memory        Check memory usage and status
  --disk          Check root disk usage and status
  --cpu           Check CPU usage and status
  -g, --cpu-graph Display CPU usage as a text graph
  --top-cpu       Show the top CPU-consuming processes
  --top-memory    Show the top memory-consuming processes
  --uptime        Show how long the server has been running
  --load          Show 1-, 5-, and 15-minute load averages
  --os            Display the operating system version
  --network       Check network connectivity
  --all           Run all health checks
  -h, --help      Display this help page

Multiple flags can be combined:
  ./health-monitor.sh --cpu --memory
  ./health-monitor.sh --disk --network
  ./health-monitor.sh --cpu --top-cpu --load
  ./health-monitor.sh --all

Exit codes:
  0  All requested checks completed successfully
  1  One or more health checks failed
  2  An unknown command-line option was supplied
HELP
}

run_all_checks() {
    local status=0
    check_memory || status=1
    check_disk || status=1
    check_cpu || status=1
    show_top_cpu || status=1
    show_top_memory || status=1
    show_uptime || status=1
    show_load_average || status=1
    show_os_version || status=1
    check_network || status=1
    return "$status"
}

pause_menu() {
    echo ""
    read -r -p "Press Enter to return to the menu..." _
}

memory_menu() {
    while true; do
        echo ""
        echo "========== MEMORY OPTIONS =========="
        echo "1. Check memory health"
        echo "2. Show memory in human-readable format (free -h)"
        echo "3. Show memory in MiB (free -m)"
        echo "4. Show memory in GiB (free -g)"
        echo "5. Show top memory-consuming processes"
        echo "6. Memory help"
        echo "0. Back to main menu"
        read -r -p "Choose an option: " choice
        case "$choice" in
            1) check_memory; pause_menu ;;
            2) free -h; pause_menu ;;
            3) free -m; pause_menu ;;
            4) free -g; pause_menu ;;
            5) show_top_memory; pause_menu ;;
            6) echo "--memory: check memory usage"; echo "--top-memory: show top memory-consuming processes"; echo "Example: ./health-monitor.sh --memory --top-memory"; pause_menu ;;
            0) return 0 ;;
            *) echo "Invalid choice. Enter 0-6." ;;
        esac
    done
}

disk_menu() {
    while true; do
        echo ""
        echo "========== DISK OPTIONS =========="
        echo "1. Check disk health"
        echo "2. Show disk space (df -h)"
        echo "3. Show block devices (lsblk)"
        echo "4. Disk help"
        echo "0. Back to main menu"
        read -r -p "Choose an option: " choice
        case "$choice" in
            1) check_disk; pause_menu ;;
            2) df -h; pause_menu ;;
            3) lsblk; pause_menu ;;
            4) echo "--disk: check root disk usage"; echo "Example: ./health-monitor.sh --disk"; pause_menu ;;
            0) return 0 ;;
            *) echo "Invalid choice. Enter 0-4." ;;
        esac
    done
}

cpu_menu() {
    while true; do
        echo ""
        echo "========== CPU OPTIONS =========="
        echo "1. Check CPU usage"
        echo "2. Show CPU usage graph"
        echo "3. Show top CPU-consuming processes"
        echo "4. CPU help"
        echo "0. Back to main menu"
        read -r -p "Choose an option: " choice
        case "$choice" in
            1) check_cpu; pause_menu ;;
            2) show_cpu_graph; pause_menu ;;
            3) show_top_cpu; pause_menu ;;
            4) echo "--cpu: check CPU usage"; echo "-g or --cpu-graph: show CPU usage graph"; echo "--top-cpu: list top CPU-consuming processes"; echo "Example: ./health-monitor.sh --cpu --top-cpu"; pause_menu ;;
            0) return 0 ;;
            *) echo "Invalid choice. Enter 0-4." ;;
        esac
    done
}

network_menu() {
    while true; do
        echo ""
        echo "========== NETWORK OPTIONS =========="
        echo "1. Check network connectivity"
        echo "2. Show IP addresses (ip addr)"
        echo "3. Show routes (ip route)"
        echo "4. Network help"
        echo "0. Back to main menu"
        read -r -p "Choose an option: " choice
        case "$choice" in
            1) check_network; pause_menu ;;
            2) ip addr; pause_menu ;;
            3) ip route; pause_menu ;;
            4) echo "--network: check network connectivity"; echo "Example: ./health-monitor.sh --network"; pause_menu ;;
            0) return 0 ;;
            *) echo "Invalid choice. Enter 0-4." ;;
        esac
    done
}

main_menu() {
    while true; do
        show_header
        echo ""
        echo "Choose an option:"
        echo "1. Memory Usage"
        echo "2. Disk Usage"
        echo "3. CPU Usage"
        echo "4. Top CPU-Consuming Processes"
        echo "5. Top Memory-Consuming Processes"
        echo "6. System Uptime"
        echo "7. Load Average"
        echo "8. OS Version"
        echo "9. Network Connectivity"
        echo "10. Run All Health Checks"
        echo "11. Help - Show all flags and descriptions"
        echo "12. Exit"
        read -r -p "Choose an option: " choice

        case "$choice" in
            1) memory_menu ;;
            2) disk_menu ;;
            3) cpu_menu ;;
            4) show_top_cpu; pause_menu ;;
            5) show_top_memory; pause_menu ;;
            6) show_uptime; pause_menu ;;
            7) show_load_average; pause_menu ;;
            8) show_os_version; pause_menu ;;
            9) network_menu ;;
            10) run_all_checks; pause_menu ;;
            11) show_help; pause_menu ;;
            12) echo "Goodbye!"; return 0 ;;
            *) echo "Invalid choice. Enter 1-12." ;;
        esac
    done
}

run_cli() {
    if (( $# == 0 )); then
        main_menu
        return $?
    fi

    local memory=0 disk=0 cpu=0 graph=0 top_cpu=0 top_memory=0 uptime=0 load=0 os=0 network=0 all=0

    while (( $# > 0 )); do
        case "$1" in
            --memory) memory=1 ;;
            --disk) disk=1 ;;
            --cpu) cpu=1 ;;
            -g|--cpu-graph) graph=1 ;;
            --top-cpu) top_cpu=1 ;;
            --top-memory) top_memory=1 ;;
            --uptime) uptime=1 ;;
            --load) load=1 ;;
            --os) os=1 ;;
            --network) network=1 ;;
            --all) all=1 ;;
            -h|--help) show_help; return 0 ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                echo "Use --help to see available options." >&2
                return 2
                ;;
        esac
        shift
    done

    show_header

    if (( all )); then
        run_all_checks
        return $?
    fi

    local status=0
    if (( memory )); then check_memory || status=1; fi
    if (( disk )); then check_disk || status=1; fi
    if (( cpu )); then check_cpu || status=1; fi
    if (( graph )); then show_cpu_graph || status=1; fi
    if (( top_cpu )); then show_top_cpu || status=1; fi
    if (( top_memory )); then show_top_memory || status=1; fi
    if (( uptime )); then show_uptime || status=1; fi
    if (( load )); then show_load_average || status=1; fi
    if (( os )); then show_os_version || status=1; fi
    if (( network )); then check_network || status=1; fi

    return "$status"
}

run_cli "$@"
exit $?
