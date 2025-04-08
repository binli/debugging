#!/bin/bash

# Number of suspends to perform
TOTAL_SUSPENDS=${1:-30}

# Loop to suspend 30 times
for ((i=1; i<=TOTAL_SUSPENDS; i++)); do
    echo "Suspend #$i of $TOTAL_SUSPENDS starting..."
    sudo rtcwake -m mem -s 10
    echo "Woke up from suspend #$i"
    sleep 2  # Brief pause to avoid overwhelming the system
done

echo "Completed $TOTAL_SUSPENDS suspends."
