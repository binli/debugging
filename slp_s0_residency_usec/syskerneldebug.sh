#!/bin/bash
# checkjournal.sh backend

# if the return value is not 0, exit for debugging
# if the return value is 0, reboot the system
#
function failrate() {
    if [ -f failrate.txt ]; then
        failrate=$(cat failrate.txt)
        failrate=$((failrate+1))
        echo $failrate > failrate.txt
    else
        echo 1 > failrate.txt
    fi
}

keywords=$(sudo cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec)
# save the keywords to a file for comparison with next reboot
if [ -f /home/$USER/pmc_core.txt ]; then
    old_keywords=$(cat /home/$USER/pmc_core.txt)
    if [ "$keywords" == "$old_keywords" ]; then
        echo "slp_s0_residency_usec is the same as before, incrementing failrate."
        failrate
    else
        echo "Keywords are the same, no action needed."
    fi
else
    old_keywords=""
    echo $keywords > /home/$USER/pmc_core.txt
fi
