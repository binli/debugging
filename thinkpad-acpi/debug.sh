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

# Get the latest thinkpad_acpi.
#curl -s https://raw.githubusercontent.com/torvalds/linux/master/drivers/platform/x86/thinkpad_acpi.c > thinkpad_acpi.c
#curl -s https://raw.githubusercontent.com/torvalds/linux/master/drivers/platform/x86/dual_accel_detect.h > dual_accel_detect.h

# Compile the thinkpad_acpi.
# make
# sudo cp /lib/modules/$(uname -r)/kernel/drivers/platform/x86/thinkpad_acpi.ko thinkpad_acpi.ko.orig
# sudo cp thinkpad_acpi.ko /lib/modules/$(uname -r)/kernel/drivers/platform/x86/
# sudo depmod -a
# sudo modprobe -r thinkpad_acpi
# dmesg | tail -n 20
#
# Or just debug in local directory.
# sudo modprobe -r thinkpad_acpi
# sudo insmod thinkpad_acpi.ko
# dmesg | tail -n 20
#
# clean the thinkpad_acpi.
# make -C /lib/modules/$(uname -r)/build M=$(pwd) clean
# sudo rm /lib/modules/$(uname -r)/kernel/drivers/platform/x86/thinkpad_acpi.ko
# sudo depmod -a
# sudo modprobe -r thinkpad_acpi
# sudo modprobe thinkpad_acpi
# install the thinkpad_acpi.
# sudo cp thinkpad_acpi.ko.orig /lib/modules/$(uname -r)/kernel/drivers/platform/x86/
