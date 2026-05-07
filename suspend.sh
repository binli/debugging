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

        ./$BACKEND
        if [ $? -ne 0 ]; then
            echo "Backend script $BACKEND returned non-zero exit code. Exiting for debugging."
            exit 1
        else
            echo "Backend script $BACKEND executed successfully."
        fi
    fi
    sleep 3  # Brief pause to avoid overwhelming the system
done

echo "Completed $TOTAL_SUSPENDS suspends."
