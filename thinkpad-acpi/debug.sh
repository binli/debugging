#!/bin/bash
# Enable the debug mode for thinkpad_acpi.
# At the second time, it will disable the debug mode.
# Usage:
# ./debug.sh
# ./debug.sh disable
# ./debug.sh enable
if [ "$1" == "disable" ]; then
    if [ -e /etc/modprobe.d/thinkpad.conf ]; then
        echo "*** Disable debug mode. ***"
        sudo rm /etc/modprobe.d/thinkpad.conf
        exit 0
    fi

elif [ "$1" == "enable" ]; then
    if [ ! -e /etc/modprobe.d/thinkpad.conf ]; then
    	sudo mkdir -p /etc/modprobe.d/
    	sudo cp thinkpad.conf /etc/modprobe.d/
    	echo -e "*** Debug mode enabled. *** Please reboot, then upload the log 'journalctl -b 0'.\n"
    fi
else
    echo "*** Build the thinkpad_acpi.ko ***"
    # After edit the thinkpad_acpi.c
    make clean
    make
    sudo rmmod thinkpad_acpi
    sudo insmod ./thinkpad_acpi.ko debug=0xfff
fi
