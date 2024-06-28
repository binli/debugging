#!/bin/bash
# checkjournal.sh backend

# if the return value is not 0, exit for debugging
# if the return value is 0, reboot the system
vendor=$(journalctl -b 0 | grep -oe 'drm_wait_one_vblank')
if [ -z "$vendor" ]; then
    echo "No drm_wait_one_vblank found in journalctl"
    exit 0
else
    echo "drm_wait_one_vblank found in journalctl, please debug!!!"
    exit 1
fi
