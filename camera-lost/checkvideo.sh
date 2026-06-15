#!/bin/bash
# checkvideo.sh

# if the return value is not 0, exit for debugging
# if the return value is 0, reboot the system
#
video0="/dev/video0"
if [ ! -c "$video0" ]; then
    echo "$video0 does not exist!"
    exit 1
else
    # check if the snapshot is segmented
    pid=$(pidof "snapshot")
    if [ -n "$pid" ]; then
        echo "snapshot is running with PID $pid"
    else
        echo "start snapshot!"
        /usr/bin/snapshot &
    fi
    exit 0
fi
