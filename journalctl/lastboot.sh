#!/usr/bin/env bash
# Get the previous log
timestamp=$(date +%Y%m%d_%H%M%S)
journalctl -k -b -1 > "kernel_log_$timestamp.log"
journalctl -b -1 > "system_log_$timestamp.log"
exit 0
