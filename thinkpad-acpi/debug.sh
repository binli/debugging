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
    # Disable the debug mode for power-profiles-daemon
    if [ -e /lib/systemd/system/power-profiles-daemon.service ]; then
        sudo sed -i 's/ExecStart=\/usr\/libexec\/power-profiles-daemon -v/ExecStart=\/usr\/libexec\/power-profiles-daemon/g' /lib/systemd/system/power-profiles-daemon.service
    fi
elif [ "$1" == "build" ]; then
    echo "*** Build the thinkpad_acpi.ko ***"
    # After edit the thinkpad_acpi.c
    make clean
    make
    sudo rmmod thinkpad_acpi
    sudo insmod ./thinkpad_acpi.ko debug=0xfff
else
    if [ ! -e /etc/modprobe.d/thinkpad.conf ]; then
        sudo mkdir -p /etc/modprobe.d/
        sudo cp thinkpad.conf /etc/modprobe.d/
        echo -e "*** Debug mode enabled for thinkpad_acpi ***\n"
    fi
    # Enable the debug mode for power-profiles-daemon
    if [ -e /lib/systemd/system/power-profiles-daemon.service ]; then
        sudo sed -i 's/ExecStart=\/usr\/libexec\/power-profiles-daemon/ExecStart=\/usr\/libexec\/power-profiles-daemon -v/g' /lib/systemd/system/power-profiles-daemon.service
        echo -e "*** Debug mode enabled for power-profiles-daemon. ***\n"
        echo -e "Please reboot, then upload the log 'journalctl -b 0' or run autoreboot.sh\n"
    fi
fi
