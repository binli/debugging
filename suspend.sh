#!/bin/bash

# Number of suspends to perform
TOTAL_SUSPENDS=${1:-30}
BACKEND=$2

# Loop to suspend 30 times
for ((i=1; i<=TOTAL_SUSPENDS; i++)); do
    echo "Suspend #$i of $TOTAL_SUSPENDS starting..."
    sudo rtcwake -m mem -s 20
    echo "Woke up from suspend #$i"
    if [ -x "$BACKEND" ]; then
        echo "Call backend script: $BACKEND"
        # get the backend return value
        # if the return value is not 0, exit for debugging
        # if the return value is 0, reboot the system
        /home/$USER/$BACKEND
    fi
    sleep 2  # Brief pause to avoid overwhelming the system
done

echo "Completed $TOTAL_SUSPENDS suspends."
