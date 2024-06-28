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

keywords=$(journalctl -b 0 | grep -oe 'drm_wait_one_vblank')
if [ -z "$keywords" ]; then
    exit 0
else
    echo "drm_wait_one_vblank found in journalctl!"
    journalctl -b 0 > vblank_$(date +%Y%m%d%H%M%S).log
    # uncomment the following two lines to debug this issue
    #echo "please debug the issue!"
    #exit 1
    failrate
    exit 0
fi
