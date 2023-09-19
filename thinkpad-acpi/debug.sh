#!/bin/bash
# Enable the debug mode for thinkpad_acpi.
# At the second time, it will disable the debug mode.
# Usage:
# ./debug.sh
# ./debug.sh disable
if [ "$1" == "disable" ]; then
    if [ -e /etc/modprobe.d/thinkpad.conf ]; then
        echo "*** Disable debug mode. ***"
        sudo rm /etc/modprobe.d/thinkpad.conf
        exit 0
    fi
fi

sudo mkdir -p /etc/modprobe.d/
sudo cp thinkpad.conf /etc/modprobe.d/
echo -e "*** Debug mode enabled. *** Please reboot, then upload the log 'journalctl -b 0'.\n"
