#!/bin/bash
# autoreboot.sh
# automatically reboot the system 30 times
# and check journalctl's result if there is 'Elan TrackPoint' in the output
#
# Usage:
#  ./autoreboot.sh 30

# check if the argument is a number
# if not, exit
if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Usage: $0 <number>"
    exit 1
fi

# check if the argument is greater than 0
# if not, exit
if [ "$1" -le 0 ]; then
    echo "Usage: $0 <number>"
    exit 1
fi

# Let Linux do autoreboot
# and check journalctl's result if there is 'Elan TrackPoint' in the output
# if there is, exit
# if not, continue
# repeat the above steps for 30 times
# if there is no 'Elan TrackPoint' in the output for 30 times, exit
# if there is 'Elan TrackPoint' in the output for 30 times, reboot
for (( i=1; i<=$1; i++ ))
do
    echo "Rebooting... $i"
    sudo reboot
    sleep 60
    if journalctl | grep -q 'Elan TrackPoint'; then
        echo "Elan TrackPoint is still there"
    else
        echo "Elan TrackPoint is gone"
        exit 1
    fi
done

