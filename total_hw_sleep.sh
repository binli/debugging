#!/usr/bin/env bash
if [ ! -f total_hw_sleep.txt ]; then
    echo 0 > total_hw_sleep.txt
fi
last_hw_sleep=$(cat total_hw_sleep.txt | tail -n 1)
current_hw_sleep=$(cat /sys/power/suspend_stats/total_hw_sleep)
if [ "$current_hw_sleep" -gt "$last_hw_sleep" ]; then
    cat /sys/power/suspend_stats/total_hw_sleep >> total_hw_sleep.txt
else
    echo "Error: total_hw_sleep did not increase. Last: $last_hw_sleep, Current: $current_hw_sleep"
    exit 1
fi
