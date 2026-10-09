#!/usr/bin/env bash
# Get the previous log
timestamp=$(date +%Y%m%d_%H%M%S)
mkdir -p logs
journalctl -k -b -1 > "logs/kernel_log_$timestamp.log"
journalctl -b -1 > "logs/system_log_$timestamp.log"
exit 0
