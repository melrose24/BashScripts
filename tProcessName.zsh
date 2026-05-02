#!/bin/zsh

# Print system uptime
echo "System Uptime: $(uptime -p)"

# List all running processes with their PID and name
echo "\nRunning Processes:"
ps -eo pid,etime,comm | tail -n +2 | while read pid etime comm; do
    # Format uptime for each process
    process_uptime=$(ps -p $pid -o etime=)
    echo "PID: $pid, Uptime: $process_uptime, Process: $comm"
done
